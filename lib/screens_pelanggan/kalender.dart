import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});

  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

// Constants moved to top level for better organization
const List<String> _timeSlots = [
  '07:00',
  '07:30',
  '08:00',
  '08:30',
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '12:00',
  '12:30',
  '13:00',
  '13:30',
  '14:00',
  '14:30',
  '15:00',
  '15:30',
  '16:00',
  '16:30',
  '17:00',
  '17:30',
  '18:00',
  '18:30',
  '19:00',
  '19:30',
  '20:00',
  '20:30',
  '21:00',
  '21:30',
  '22:00',
  '22:30',
];

// Data model for better type safety
class CourtSlotData {
  final bool isAvailable;
  final bool isClosed;

  const CourtSlotData({required this.isAvailable, required this.isClosed});
}

class _HalamanKalenderState extends State<HalamanKalender> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;

  // Improved data structure with type safety
  Map<String, Map<String, CourtSlotData>> bookingData = {};
  List<String> courtIds = [];
  Set<String> processingCells = {};

  // Cache for user data
  String? _cachedUsername;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Consolidated initialization method
  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadOrCreateSlots(selectedDate);
  }

  // Cache user data to avoid repeated SharedPreferences calls
  Future<void> _loadUserData() async {
    if (_cachedUsername == null) {
      final prefs = await SharedPreferences.getInstance();
      _cachedUsername = prefs.getString('username') ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildStatusLegend(),
          _buildCalendarContent(),
        ],
      ),
    );
  }

  // Extracted widget methods for better organization
  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _formatDate(selectedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDateNavigationButton(
                icon: Icons.arrow_back,
                onPressed:
                    () => _changeDate(
                      selectedDate.subtract(const Duration(days: 1)),
                    ),
                isPrimary: false,
              ),
              const SizedBox(width: 16),
              _buildDateNavigationButton(
                text: 'Hari Ini',
                onPressed: () => _changeDate(DateTime.now()),
                isPrimary: true,
              ),
              const SizedBox(width: 16),
              _buildDateNavigationButton(
                icon: Icons.arrow_forward,
                onPressed:
                    () =>
                        _changeDate(selectedDate.add(const Duration(days: 1))),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigationButton({
    IconData? icon,
    String? text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? primaryColor : Colors.white,
        foregroundColor: isPrimary ? Colors.white : primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: icon != null ? Icon(icon) : Text(text!),
    );
  }

  Widget _buildStatusLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Tersedia', availableColor),
          _buildLegendItem('Telah Dibooking', bookedColor),
          _buildLegendItem('Tutup', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCalendarContent() {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text('Memuat data booking...'),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => _loadOrCreateSlots(selectedDate),
        color: primaryColor,
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildCalendarTable(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarTable() {
    final sortedCourtIds = _getSortedCourtIds();

    return Column(
      children: [
        _buildTableHeader(sortedCourtIds),
        ...bookingData.entries.map(
          (entry) => _buildTableRow(entry.key, entry.value, sortedCourtIds),
        ),
      ],
    );
  }

  Widget _buildTableHeader(List<String> sortedCourtIds) {
    return Container(
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Jam', width: 110),
          ...sortedCourtIds.map(
            (id) => _buildHeaderCell('Lapangan $id', width: 110),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String time,
    Map<String, CourtSlotData> courts,
    List<String> sortedCourtIds,
  ) {
    return Row(
      children: [
        _buildTimeCell(time, width: 110),
        ...sortedCourtIds.map((id) {
          final courtData =
              courts[id] ??
              const CourtSlotData(isAvailable: true, isClosed: false);
          debugPrint('time : $time');
          return _buildCourtCell(
            time,
            id,
            courtData.isAvailable,
            courtData.isClosed,
          );
        }),
      ],
    );
  }

  List<String> _getSortedCourtIds() {
    return courtIds.toList()..sort((a, b) {
      final aNumber = int.tryParse(RegExp(r'\d+').stringMatch(a) ?? '') ?? 0;
      final bNumber = int.tryParse(RegExp(r'\d+').stringMatch(b) ?? '') ?? 0;
      return aNumber.compareTo(bNumber);
    });
  }

  void _changeDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadOrCreateSlots(date);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static const List<String> daftarHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  Future<void> _loadCourts() async {
    try {
      final courtsSnapshot =
          await FirebaseFirestore.instance.collection('lapangan').get();
      courtIds =
          courtsSnapshot.docs.map((doc) => doc['nomor'].toString()).toList();
    } catch (e) {
      debugPrint('Error loading courts: $e');
      // Handle error gracefully
      courtIds = [];
    }
  }

  Future<void> _buildBookingData(List<TimeSlot> slots) async {
    setState(() => isLoading = true);

    try {
      await _loadCourts();

      if (!mounted) return;

      Map<String, Map<String, CourtSlotData>> tempData = {};

      // Initialize all time slots with default values
      for (final slot in slots) {
        final timeRange = '${slot.startTime} - ${slot.endTime}';

        tempData.putIfAbsent(
          timeRange,
          () => {
            for (var courtId in courtIds)
              courtId: const CourtSlotData(isAvailable: true, isClosed: false),
          },
        );

        tempData[timeRange]![slot.courtId] = CourtSlotData(
          isAvailable: slot.isAvailable,
          isClosed: slot.isClosed,
        );
      }

      setState(() {
        bookingData = tempData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error building booking data: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Gagal memuat data booking');
    }
  }

  Future<void> _loadOrCreateSlots(DateTime selectedDate) async {
    setState(() => isLoading = true);

    try {
      final dateStr = _formatDateString(selectedDate);
      final slots = await FirebaseService().getTimeSlotsByDate(dateStr);

      if (slots.isEmpty) {
        await FirebaseService().generateSlotsOneDay(selectedDate);
        final newSlots = await FirebaseService().getTimeSlotsByDate(dateStr);
        await _buildBookingData(newSlots);
      } else {
        await _buildBookingData(slots);
      }
    } catch (e) {
      debugPrint('Error loading slots: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Gagal memuat data slot');
    }
  }

  String _formatDateString(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _performBooking(
    String startTime,
    String endTime,
    String court,
    DateTime selectedDate,
    String username,
  ) async {
    try {
      final dateStr = _formatDateString(selectedDate);

      final startTotalMinutes = _timeToMinutes(startTime);
      final endTotalMinutes = _timeToMinutes(endTime);
      double totalHours = (endTotalMinutes - startTotalMinutes) / 60.0;

      // Book each 30-minute slot
      for (
        int minutes = startTotalMinutes;
        minutes < endTotalMinutes;
        minutes += 30
      ) {
        final formattedTime = _minutesToFormattedTime(minutes);
        final formatStartTime = formattedTime.replaceAll(':', '');
        final slotId = '${court}_${dateStr}_$formatStartTime';

        await FirebaseService().bookSlotForNonMember(
          slotId,
          username,
          totalHours,
        );

        totalHours = 0;
      }

      await FirebaseService().addTotalBooking(username);
    } catch (e) {
      debugPrint('Error performing booking: $e');
      rethrow;
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _minutesToFormattedTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _namaHari(int weekday) => daftarHari[weekday - 1];

  bool _isHariDalamRange(String hari, String mulai, String selesai) {
    final indexHari = daftarHari.indexOf(hari);
    final indexMulai = daftarHari.indexOf(mulai);
    final indexSelesai = daftarHari.indexOf(selesai);

    if (indexMulai <= indexSelesai) {
      return indexHari >= indexMulai && indexHari <= indexSelesai;
    } else {
      // Range seperti "Jumat - Senin"
      return indexHari >= indexMulai || indexHari <= indexSelesai;
    }
  }

  // Price Calculation - Updated untuk Member/Non-Member
  Future<double> _calculateTotalPrice({
    required String startTime,
    required String endTime,
    required DateTime selectedDate,
    required String type,
  }) async {
    try {
      final hargaList = await FirebaseService().getHarga();
      final hariBooking = _namaHari(selectedDate.weekday);

      final startMinutes = _timeToMinutes(startTime);
      final endMinutes = _timeToMinutes(endTime);

      double totalPrice = 0;

      for (int time = startMinutes; time < endMinutes; time += 30) {
        final jam = time ~/ 60;

        // Cari harga yang sesuai dengan type (Member/Non-Member)
        final hargaMatch = hargaList.where((harga) =>
            harga.type == type &&
            _isHariDalamRange(hariBooking, harga.hariMulai, harga.hariSelesai) &&
            jam >= harga.startTime &&
            jam < harga.endTime).firstOrNull;

        if (hargaMatch != null) {
          totalPrice += hargaMatch.harga / 2; // 30 menit = 0.5 jam
        } else {
          // Fallback jika tidak ada harga yang cocok
          debugPrint('No matching price found for: $type, $hariBooking, $jam:${time % 60}');
        }
      }

      return totalPrice;
    } catch (e) {
      debugPrint('Error calculating price: $e');
      return 0;
    }
  }

  Widget _buildConfirmationDialog(
    String startTime,
    String endTime,
    String court,
    DateTime selectedDate,
    String username,
  ) {
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text(
            'Konfirmasi Booking',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah anda yakin ingin booking?',
                style: TextStyle(fontSize: 18),
              ),
              
              const SizedBox(height: 16),

              FutureBuilder<double>(
              future: _calculateTotalPrice(
                startTime: startTime,
                endTime: endTime,
                selectedDate: selectedDate,
                type: 'Non Member', 
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Menghitung harga...');
                } else if (snapshot.hasError) {
                  return Text('Gagal menghitung harga: ${snapshot.error}');
                } else {
                  final price = snapshot.data ?? 0;
                  return Text(
                    'Total Harga: Rp ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  );
                }
              },
            ),
              const SizedBox(height: 10),
              const Text(
                'Catatan: Booking tidak dikenakan DP, harap datang sesuai jadwal yang dipilih',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (isLoading) ...[
                const SizedBox(height: 20),
                const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Sedang memproses booking...'),
                  ],
                ),
              ],
            ],
          ),
          actions:
              isLoading
                  ? []
                  : [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() => isLoading = true);

                        try {
                          await _performBooking(
                            startTime,
                            endTime,
                            court,
                            selectedDate,
                            username,
                          );
                          await _updateSlot(selectedDate);

                          if (!context.mounted) return;

                          _showSuccessSnackBar(
                            'Berhasil booking Lapangan $court pada hari ${_formatDate(selectedDate)} pukul $startTime - $endTime',
                          );

                          Navigator.pop(context);
                        } catch (e) {
                          setState(() => isLoading = false);
                          _showErrorSnackBar('Gagal melakukan booking: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: const Text(
                        'Konfirmasi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
        );
      },
    );
  }

  Future<void> _updateSlot(DateTime selectedDate) async {
    try {
      final dateStr = _formatDateString(selectedDate);
      final updatedSlots = await FirebaseService().getTimeSlotsByDate(dateStr);
      await _buildBookingData(updatedSlots);
    } catch (e) {
      debugPrint('Error updating slot: $e');
      _showErrorSnackBar('Gagal memperbarui data');
    }
  }

  bool _isTimePast(String timeSlot, DateTime date) {
    try {
      final now = DateTime.now();
      final endTime = timeSlot.split(' - ')[1];
      final timeParts = endTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final slotDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      return slotDateTime.isBefore(now);
    } catch (e) {
      debugPrint("Error parsing timeSlot: $e");
      return false;
    }
  }

  String _getCellKey(String time, String court) => '${time}_$court';

  Future<void> _showBookingDialog(
    String time,
    String court,
    bool isAvailable,
    bool isClosed,
    DateTime selectedDate,
  ) async {
    final cellKey = _getCellKey(time, court);

    if (processingCells.contains(cellKey)) {
      _showWarningSnackBar('Sedang memproses, mohon tunggu...');
      return;
    }

    setState(() => processingCells.add(cellKey));

    try {
      if (isClosed) {
        _showWarningSnackBar('Lapangan ditutup pada waktu ini');
        return;
      }

      await _loadUserData();
      final username = _cachedUsername ?? '';

      if (!isAvailable) {
        _showBookingInfoDialog(time, court, selectedDate, isAvailable: false);
        return;
      }

      final maxConsecutiveSlots = await _calculateMaxConsecutiveSlots(
        time,
        court,
        selectedDate,
      );
      _showBookingSelectionDialog(
        time,
        court,
        selectedDate,
        username,
        maxConsecutiveSlots,
      );
    } finally {
      setState(() => processingCells.remove(cellKey));
    }
  }

  Future<int> _calculateMaxConsecutiveSlots(
    String time,
    String court,
    DateTime selectedDate,
  ) async {
    try {
      final startTime = time.split(' - ')[0];
      final startIndex = _timeSlots.indexOf(startTime);

      if (startIndex == -1) return 1;

      final currentHour = int.parse(startTime.split(':')[0]);
      final currentMinute = int.parse(startTime.split(':')[1]);
      final startTotalMinutes = currentHour * 60 + currentMinute;
      final remainingMinutes = (23 * 60) - startTotalMinutes;
      final maxPossibleSlots = remainingMinutes ~/ 30;

      final slotStatuses = await FirebaseService().getSlotRangeAvailability(
        startTime: startTime,
        court: court,
        date: selectedDate,
        maxSlots: maxPossibleSlots,
      );

      int consecutiveSlots = 1;
      for (int i = 0; i < slotStatuses.length; i++) {
        final slot = slotStatuses[i];
        if (slot.isAvailable && !slot.isClosed) {
          consecutiveSlots++;
        } else {
          break;
        }
      }

      return consecutiveSlots;
    } catch (e) {
      debugPrint('Error calculating consecutive slots: $e');
      return 1;
    }
  }

  void _showBookingInfoDialog(
    String time,
    String court,
    DateTime selectedDate, {
    required bool isAvailable,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              isAvailable ? 'Booking Lapangan' : 'Lapangan Telah Dibooking',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${_formatDate(selectedDate)}'),
                Text('Waktu: $time'),
                Text('Lapangan: $court'),
                if (!isAvailable)
                  const Text(
                    'Status: Telah dibooking',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showBookingSelectionDialog(
    String time,
    String court,
    DateTime selectedDate,
    String username,
    int maxSlots,
  ) {
    int selectedDuration = 1; // Move it here to persist across rebuilds
    final startTime = time.split(' - ')[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final endTime = _calculateEndTime(startTime, selectedDuration);

            return AlertDialog(
              title: const Text('Booking Lapangan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal: ${_formatDate(selectedDate)}'),
                  Text('Waktu mulai: $startTime'),
                  Text('Lapangan: $court'),
                  const SizedBox(height: 16),
                  const Text('Durasi booking:'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<int>(
                      value: selectedDuration,
                      isExpanded: true,
                      underline: Container(),
                      onChanged: (value) {
                        setState(() {
                          selectedDuration =
                              value!; // Update the outer variable
                        });
                      },
                      items:
                          List.generate(maxSlots, (i) => i + 1).map((duration) {
                            final endTime = _calculateEndTime(
                              startTime,
                              duration,
                            );
                            return DropdownMenuItem(
                              value: duration,
                              child: Text('$endTime (${duration * 30} menit)'),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Waktu selesai: $endTime',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder:
                          (context) => _buildConfirmationDialog(
                            startTime,
                            endTime,
                            court,
                            selectedDate,
                            username,
                          ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _calculateEndTime(String startTime, int durationSlots) {
    final startTotalMinutes = _timeToMinutes(startTime);
    final endTotalMinutes = startTotalMinutes + (durationSlots * 30);
    debugPrint(
      'startTotalMinutes: $startTotalMinutes, endTotalMinutes: $endTotalMinutes',
    );
    return _minutesToFormattedTime(endTotalMinutes);
  }

  // Utility methods for showing different types of messages
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Widget builder methods
  Widget _buildHeaderCell(String text, {double width = 110}) {
    return Container(
      width: width,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primaryColor,
        border: Border.all(color: Colors.white, width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimeCell(String time, {double width = 110}) {
    return Container(
      width: width,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCourtCell(
    String time,
    String court,
    bool isAvailable,
    bool isClosed,
  ) {
    final isPast = _isTimePast(time, selectedDate);
    final cellKey = _getCellKey(time, court);
    final isProcessing = processingCells.contains(cellKey);

    Color backgroundColor;
    Color textColor;
    String displayText;

    if (isClosed) {
      backgroundColor = Colors.grey;
      textColor = Colors.white;
      displayText = 'Tutup';
    } else if (isAvailable) {
      backgroundColor = availableColor;
      textColor = Colors.green.shade700;
      displayText = 'Tersedia';
    } else {
      backgroundColor = bookedColor;
      textColor = Colors.red.shade700;
      displayText = 'Telah Dibooking';
    }

    // Function to handle cell tap with appropriate feedback
    void handleCellTap() {
      if (isPast) {
        _showWarningSnackBar('Waktu ini sudah lewat, tidak bisa dibooking');
        return;
      }
      _showBookingDialog(time, court, isAvailable, isClosed, selectedDate);
    }

    return GestureDetector(
      onTap: isProcessing ? null : handleCellTap,
      child: Container(
        width: 110,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child:
            isProcessing
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
                : Text(
                  displayText,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
      ),
    );
  }
}
