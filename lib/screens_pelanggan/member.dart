import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HalamanMember extends StatefulWidget {
  const HalamanMember({super.key});

  @override
  State<HalamanMember> createState() => _HalamanMemberState();
}

class _HalamanMemberState extends State<HalamanMember> {
  // State variables
  String? selectedStartTime;
  String? selectedEndTime;
  int? selectedWeekday;
  List<DateTime> selectedDates = [];
  List<AllCourts> courts = [];
  bool isLoading = false;

  // Controllers
  late final TextEditingController startTimeController;
  late final TextEditingController endTimeController;

  // Constants
  static const Duration _slotDuration = Duration(minutes: 30);
  static const int _startHour = 7;
  static const int _endHour = 23;
  
  // Static data - no need to recreate every time
  static final List<String> _timeOptions = _generateTimeOptions();
  static const Map<String, int> _weekdayMap = {
    'Senin': 1,
    'Selasa': 2,
    'Rabu': 3,
    'Kamis': 4,
    'Jumat': 5,
    'Sabtu': 6,
    'Minggu': 7,
  };

  @override
  void initState() {
    super.initState();
    startTimeController = TextEditingController();
    endTimeController = TextEditingController();
    _initializeData();
  }

  @override
  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  // Initialization methods
  Future<void> _initializeData() async {
    await _loadCourts();
  }

  Future<void> _loadCourts() async {
    if (courts.isNotEmpty) return; // Avoid unnecessary API calls
    
    try {
      final loadedCourts = await FirebaseService().getAllLapangan();
      if (mounted) {
        setState(() {
          courts = loadedCourts;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal memuat data lapangan: $e');
      }
    }
  }

  // Static methods for better performance
  static List<String> _generateTimeOptions() {
    final List<String> timeOptions = [];
    DateTime currentTime = DateTime(0, 1, 1, _startHour, 0);
    final DateTime endTime = DateTime(0, 1, 1, _endHour, 0);

    while (currentTime.isBefore(endTime)) {
      timeOptions.add(DateFormat.Hm().format(currentTime));
      currentTime = currentTime.add(_slotDuration);
    }
    return timeOptions;
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _minutesToTime(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
  }

  // Business logic methods
  List<DateTime> _getWeekdaysInRange(int weekday, DateTime baseDate) {
    final endDate = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
    final daysDifference = endDate.difference(baseDate).inDays + 1;
    
    return List.generate(daysDifference, (i) => baseDate.add(Duration(days: i)))
        .where((date) => date.weekday == weekday)
        .toList();
  }

  String _getWeekdayName(int weekday) {
    return _weekdayMap.entries
        .firstWhere((entry) => entry.value == weekday, orElse: () => const MapEntry('', 0))
        .key;
  }

  // Validation methods
  bool _validateInputs() {
    if (selectedStartTime == null || selectedEndTime == null || selectedDates.isEmpty) {
      _showErrorSnackBar('Lengkapi semua pilihan terlebih dahulu.');
      return false;
    }

    final start = DateFormat.Hm().parse(selectedStartTime!);
    final end = DateFormat.Hm().parse(selectedEndTime!);

    if (!end.isAfter(start)) {
      _showErrorSnackBar('Jam selesai harus setelah jam mulai.');
      return false;
    }

    return true;
  }

  // API interaction methods
  Future<bool> _checkSlotAvailability() async {
    if (courts.isEmpty) {
      await _loadCourts();
      debugPrint('Lapangan masih kosong, memuat ulang...');
    }

    if (courts.isEmpty) {
      _showErrorSnackBar('Tidak ada lapangan yang tersedia');
      return false;
    }

    final startMinutes = _timeToMinutes(selectedStartTime!);
    final endMinutes = _timeToMinutes(selectedEndTime!);

    for (final court in courts) {
      if (await _isCourtAvailableForAllDates(court, startMinutes, endMinutes)) {
        _showConfirmationDialog(court.courtId);
        return true;
      }
      debugPrint(
        'Lapangan ${court.courtId} tidak tersedia pada waktu yang dipilih.',
      );
    }

    _showErrorSnackBar('Jadwal yang dipilih tidak tersedia');
    return false;
  }

  Future<bool> _isCourtAvailableForAllDates(
    AllCourts court,
    int startMinutes,
    int endMinutes,
  ) async {
    for (final date in selectedDates) {
      for (int slotStart = startMinutes; slotStart < endMinutes; slotStart += 30) {
        final slotTime = _minutesToTime(slotStart);
        final isAvailable = await FirebaseService().isSlotAvailable(
          slotTime,
          court.courtId,
          date,
        );

        debugPrint(
          'Cek ketersediaan: ${court.courtId} pada ${date.toIso8601String()} jam $slotTime: $isAvailable',
        );
        
        if (!isAvailable) return false;
      }
    }
    return true;
  }

  Future<void> _becomeMember(String courtId) async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';

      if (username.isEmpty) {
        throw Exception('Username tidak ditemukan');
      }

      // Update user status
      await FirebaseService().nonMemberToMember(username);

      // Book slots
      await _bookAllSlots(courtId, username);

      if (mounted) {
        _showSuccessSnackBar('Selamat! Anda berhasil menjadi member');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal menjadi member: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _bookAllSlots(String courtId, String username) async {
    final startMinutes = _timeToMinutes(selectedStartTime!);
    final endMinutes = _timeToMinutes(selectedEndTime!);
    final dateFormatter = DateFormat('yyyy-MM-dd');

    for (final date in selectedDates) {
      final dateStr = dateFormatter.format(date);
      
      for (int minute = startMinutes; minute < endMinutes; minute += 30) {
        final slotTime = _minutesToTime(minute).replaceAll(':', '');
        final slotId = '${courtId}_${dateStr}_$slotTime';
        
        debugPrint('Booking slot: $slotId');
        await FirebaseService().bookSlotForMember(slotId, username);
      }
    }
  }

  // UI helper methods
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showConfirmationDialog(String courtId) {
    showDialog(
      context: context,
      builder: (context) => _ConfirmationDialog(
        courtId: courtId,
        startTime: selectedStartTime!,
        endTime: selectedEndTime!,
        selectedDates: selectedDates,
        onConfirm: () => _becomeMember(courtId),
        getWeekdayName: _getWeekdayName,
      ),
    );
  }

  Future<void> _onCheckAvailability() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);
    
    try {
      await _checkSlotAvailability();
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _onWeekdaySelected(String day) {
    final weekday = _weekdayMap[day];
    if (weekday == null) return;

    setState(() {
      selectedWeekday = weekday;
      selectedDates = _getWeekdaysInRange(weekday, DateTime.now());
    });
  }

  void _onStartTimeSelected(String time) {
    setState(() {
      selectedStartTime = time;
      startTimeController.text = time;
    });
  }

  void _onEndTimeSelected(String time) {
    setState(() {
      selectedEndTime = time;
      endTimeController.text = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayo Jadi Member'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildWeekdaySelector(),
                const SizedBox(height: 20),
                _buildTimeSelector(
                  'Pilih Jam Mulai',
                  'Pilih waktu mulai',
                  _onStartTimeSelected,
                ),
                const SizedBox(height: 20),
                _buildTimeSelector(
                  'Pilih Jam Selesai',
                  'Pilih waktu selesai',
                  _onEndTimeSelected,
                ),
                const SizedBox(height: 30),
                _buildCheckButton(),
              ],
            ),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Hari',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _weekdayMap.keys.map((day) {
              final isSelected = _weekdayMap[day] == selectedWeekday;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  onSelected: (_) => _onWeekdaySelected(day),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    String title,
    String hint,
    void Function(String) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _timeOptions.where(
              (option) => option.contains(textEditingValue.text.toLowerCase()),
            );
          },
          onSelected: onSelected,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCheckButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _onCheckAvailability,
      child: Text(
        isLoading ? 'Sedang Mencari...' : 'Cek Ketersediaan Waktu',
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Separate widget for better organization and performance
class _ConfirmationDialog extends StatelessWidget {
  final String courtId;
  final String startTime;
  final String endTime;
  final List<DateTime> selectedDates;
  final VoidCallback onConfirm;
  final String Function(int) getWeekdayName;

  const _ConfirmationDialog({
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.selectedDates,
    required this.onConfirm,
    required this.getWeekdayName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detail Informasi'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Lapangan', courtId),
            _buildInfoRow('Jam Mulai', startTime),
            _buildInfoRow('Jam Selesai', endTime),
            const SizedBox(height: 10),
            const Text(
              'Tanggal dipilih:',
              style: TextStyle(fontSize: 18),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: selectedDates.length,
                itemBuilder: (context, index) {
                  final date = selectedDates[index];
                  final weekdayName = getWeekdayName(date.weekday);
                  final formattedDate = DateFormat('dd MMM yyyy').format(date);
                  
                  return ListTile(
                    title: Text('$weekdayName, $formattedDate'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Jadi Member'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}