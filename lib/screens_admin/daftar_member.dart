import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/constants_file.dart';

class HalamanMemberAdmin extends StatefulWidget {
  const HalamanMemberAdmin({super.key});

  @override
  State<HalamanMemberAdmin> createState() => _HalamanMemberAdminState();
}

class _HalamanMemberAdminState extends State<HalamanMemberAdmin> {
  // Time selection state
  String? selectedStartTime;
  String? selectedEndTime;
  
  // Date selection state
  int? selectedWeekday;
  List<DateTime> selectedDates = [];
  
  // Court and availability state
  List<AllCourts> courts = [];
  List<AvailableForMember> availableSlots = [];
  
  // Loading and UI state
  bool isLoading = false;
  bool isCourtsLoading = true;
  bool hasCheckedAvailability = false;
  
  // Form controllers
  late TextEditingController startTimeController;
  late TextEditingController endTimeController;
  late TextEditingController usernameController;

  // Constants
  static const int _slotDurationMinutes = 30;
  static const int _startHour = 7;
  static const int _endHour = 23;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCourts();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // Initialization methods
  void _initializeControllers() {
    startTimeController = TextEditingController();
    endTimeController = TextEditingController();
    usernameController = TextEditingController();
  }

  void _disposeControllers() {
    startTimeController.dispose();
    endTimeController.dispose();
    usernameController.dispose();
  }

  // Court management
  Future<void> _loadCourts() async {
    if (!mounted) return;
    
    setState(() => isCourtsLoading = true);
    
    try {
      final loadedCourts = await FirebaseService().getAllLapangan();
      if (mounted) {
        setState(() {
          courts = loadedCourts;
          isCourtsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isCourtsLoading = false);
        _showErrorSnackBar('Gagal memuat data lapangan: $e');
      }
    }
  }

  // Time generation and validation
  List<String> _generateTimeOptions() {
    final timeOptions = <String>[];
    final startTime = DateTime(0, 1, 1, _startHour, 0);
    final endTime = DateTime(0, 1, 1, _endHour, 0);
    
    DateTime current = startTime;
    while (current.isBefore(endTime)) {
      timeOptions.add(DateFormat.Hm().format(current));
      current = current.add(const Duration(minutes: _slotDurationMinutes));
    }
    
    return timeOptions;
  }

  bool _isValidTimeRange(String startTime, String endTime) {
    try {
      final start = DateFormat.Hm().parse(startTime);
      final end = DateFormat.Hm().parse(endTime);
      return end.isAfter(start);
    } catch (e) {
      return false;
    }
  }

  // Date management
  List<DateTime> _getWeekdaysInRange(int weekday, DateTime baseDate) {
    final endDate = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
    final totalDays = endDate.difference(baseDate).inDays + 1;
    
    return List.generate(totalDays, (i) => baseDate.add(Duration(days: i)))
        .where((date) => date.weekday == weekday)
        .toList();
  }

  String _getWeekdayName(int weekday) {
    const weekdayNames = {
      1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis',
      5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'
    };
    return weekdayNames[weekday] ?? '';
  }

  // Time conversion utilities
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _minutesToTime(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
  }

  String _minutesToSlotFormat(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours$mins';
  }

  // Availability checking
  Future<void> _checkAvailability() async {
    if (!_validateSelections()) return;

    setState(() {
      isLoading = true;
      availableSlots = [];
      hasCheckedAvailability = false;
    });

    try {
      final allSlots = <AvailableForMember>[];
      
      for (final date in selectedDates) {
        final slots = await FirebaseService().getAvailableSlotsForMember(
          date,
          selectedStartTime!,
          selectedEndTime!,
        );
        allSlots.addAll(slots);
      }

      setState(() {
        availableSlots = allSlots;
        hasCheckedAvailability = true;
      });

      await _findAvailableCourt();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Terjadi kesalahan saat mengecek ketersediaan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _findAvailableCourt() async {
    if (courts.isEmpty) {
      _showErrorSnackBar('Data lapangan belum dimuat');
      return;
    }

    final startMinutes = _timeToMinutes(selectedStartTime!);
    final endMinutes = _timeToMinutes(selectedEndTime!);

    for (final court in courts) {
      if (await _isCourtAvailableForAllDates(court.courtId, startMinutes, endMinutes)) {
        _showBookingConfirmationDialog(court.courtId);
        return;
      }
    }

    _showErrorSnackBar('Tidak ada lapangan yang tersedia untuk jadwal yang dipilih');
  }

  Future<bool> _isCourtAvailableForAllDates(String courtId, int startMinutes, int endMinutes) async {
    for (final date in selectedDates) {
      for (int slotStart = startMinutes; slotStart < endMinutes; slotStart += _slotDurationMinutes) {
        final slotStartTime = _minutesToTime(slotStart);
        final isAvailable = await FirebaseService().isSlotAvailable(
          slotStartTime,
          courtId,
          date,
        );
        
        if (!isAvailable) return false;
      }
    }
    return true;
  }

  // Member registration
  Future<void> _registerMember(String courtId) async {
    final username = usernameController.text.trim();
    
    if (username.isEmpty) {
      _showErrorSnackBar('Username tidak boleh kosong');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Check if user exists
      final userExists = await FirebaseService().checkUser(username);
      if (!userExists) {
        _showErrorSnackBar('Username tidak ditemukan');
        return;
      }

      // Book all slots
      await _bookAllSlots(courtId, username);

      if (mounted) {
        _showSuccessSnackBar('Berhasil mendaftarkan customer menjadi member');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal mendaftarkan member: $e');
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

    for (final date in selectedDates) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      for (int minute = startMinutes; minute < endMinutes; minute += _slotDurationMinutes) {
        final slotTime = _minutesToSlotFormat(minute);
        final slotId = '${courtId}_${dateStr}_$slotTime';
        
        await FirebaseService().bookSlotForMember(slotId, username);
      }

      if (date == selectedDates.first) {
        await FirebaseService().nonMemberToMember(username, dateStr);
      }
    }
  }

  // Validation
  bool _validateSelections() {
    if (selectedStartTime == null || selectedEndTime == null) {
      _showErrorSnackBar('Pilih jam mulai dan jam selesai terlebih dahulu');
      return false;
    }

    if (selectedDates.isEmpty) {
      _showErrorSnackBar('Pilih hari terlebih dahulu');
      return false;
    }

    if (!_isValidTimeRange(selectedStartTime!, selectedEndTime!)) {
      _showErrorSnackBar('Jam selesai harus setelah jam mulai');
      return false;
    }

    return true;
  }

  // UI Helper methods
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Dialog methods
  void _showBookingConfirmationDialog(String courtId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Booking'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Lapangan', courtId),
              _buildInfoRow('Jam Mulai', selectedStartTime!),
              _buildInfoRow('Jam Selesai', selectedEndTime!),
              const SizedBox(height: 16),
              const Text(
                'Tanggal yang dipilih:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: selectedDates.length,
                  itemBuilder: (context, index) {
                    final date = selectedDates[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${_getWeekdayName(date.weekday)}, ${DateFormat('dd MMM yyyy').format(date)}',
                        style: const TextStyle(fontSize: 14),
                      ),
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showUsernameInputDialog(courtId);
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showUsernameInputDialog(String courtId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Input Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan username customer yang akan didaftarkan sebagai member:'),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                prefixIcon: const Icon(Icons.person, color: primaryColor),
                labelText: "Username",
                hintText: "Masukkan username",
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _registerMember(courtId),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              usernameController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _registerMember(courtId);
            },
            child: const Text('Daftarkan Member'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const weekdayMap = {
      'Senin': 1, 'Selasa': 2, 'Rabu': 3, 'Kamis': 4,
      'Jumat': 5, 'Sabtu': 6, 'Minggu': 7
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftarkan Member'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          if (isCourtsLoading)
            const Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Day selection
                  const Text(
                    'Pilih Hari',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: weekdayMap.entries.map((entry) {
                        final isSelected = entry.value == selectedWeekday;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(
                              entry.key,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            onSelected: (_) {
                              setState(() {
                                selectedWeekday = entry.value;
                                selectedDates = _getWeekdaysInRange(
                                  entry.value,
                                  DateTime.now(),
                                );
                                hasCheckedAvailability = false;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Start time selection
                  const Text(
                    'Pilih Jam Mulai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _generateTimeOptions().where(
                        (option) => option.contains(textEditingValue.text),
                      );
                    },
                    onSelected: (selection) {
                      setState(() {
                        selectedStartTime = selection;
                        hasCheckedAvailability = false;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Pilih waktu mulai (contoh: 07:00)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // End time selection
                  const Text(
                    'Pilih Jam Selesai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return _generateTimeOptions().where(
                        (option) => option.contains(textEditingValue.text),
                      );
                    },
                    onSelected: (selection) {
                      setState(() {
                        selectedEndTime = selection;
                        hasCheckedAvailability = false;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Pilih waktu selesai (contoh: 09:00)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Check availability button
                  ElevatedButton(
                    onPressed: isLoading ? null : _checkAvailability,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isLoading ? 'Sedang Mencari...' : 'Cek Ketersediaan & Daftarkan Member',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  // Selected dates display
                  if (selectedDates.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal yang dipilih (${selectedDates.length} hari):',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...selectedDates.take(3).map((date) => Text(
                              '${_getWeekdayName(date.weekday)}, ${DateFormat('dd MMM yyyy').format(date)}',
                            )),
                            if (selectedDates.length > 3)
                              Text('... dan ${selectedDates.length - 3} tanggal lainnya'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}