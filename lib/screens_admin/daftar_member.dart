import 'package:flutter_application_1/screens_admin/customers.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/court_model.dart';
import 'package:flutter_application_1/function/price/price.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/court/firebase_get_court.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';
import 'package:flutter_application_1/services/booking/member/booking_member.dart';
import 'package:flutter_application_1/services/time_slot/firebase_check_time_slot.dart';
import 'package:flutter_application_1/constants_file.dart';

class HalamanMemberAdmin extends StatefulWidget {
  const HalamanMemberAdmin({super.key});

  @override
  State<HalamanMemberAdmin> createState() => _HalamanMemberAdminState();
}

class _HalamanMemberAdminState extends State<HalamanMemberAdmin> {
  TimeOfDay jamMulai = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay jamSelesai = const TimeOfDay(hour: 8, minute: 0);

  List<String> selectedCourts = [];

  // Time selection state
  String selectedStartTime = '07:00';
  String selectedEndTime = '08:00';

  // Date selection state
  int? selectedWeekday;

  List<DateTime> selectedDates = [];

  // Court and availability state
  List<CourtModel> courts = [];
  List<CourtModel> availableCourts = [];
  List<TimeSlotModel> availableSlots = [];

  // Loading and UI state
  bool isLoading = false;
  bool isCourtsLoading = true;
  bool hasCheckedAvailability = false;

  // Form controllers
  late TextEditingController usernameController;

  // Constants
  static const int _slotDurationMinutes = 30;

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
    usernameController = TextEditingController();
  }

  void _disposeControllers() {
    usernameController.dispose();
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Court management
  Future<void> _loadCourts() async {
    if (!mounted) return;

    setState(() => isCourtsLoading = true);

    try {
      final loadedCourts = await FirebaseGetCourt().getCourts();
      if (mounted) {
        setState(() {
          courts = loadedCourts;
          isCourtsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isCourtsLoading = false);
        showErrorSnackBar(context, 'Gagal memuat data lapangan: $e');
      }
    }
  }

  bool _isValidTimeRange(String startTime, String endTime) {
    try {
      final start = DateFormat.Hm().parse(startTime);
      final end = DateFormat.Hm().parse(endTime);
      return end.isAfter(start);
    } catch (e) {
      print('Error parsing time: $e');
      return false;
    }
  }

  bool isTimeValid() {
    int startMinutes = jamMulai.hour * 60 + jamMulai.minute;
    int endMinutes = jamSelesai.hour * 60 + jamSelesai.minute;
    return startMinutes < endMinutes;
  }

  int timeToMinutes(String time) {
    final finalTime = time.split(' ');
    final parts = finalTime[0].split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Date management
  List<DateTime> _getWeekdaysInRange(int weekday, DateTime baseDate) {
    final endDate = DateTime(baseDate.year, baseDate.month + 1, 0);
    final totalDays = endDate.difference(baseDate).inDays + 1;

    return List.generate(
      totalDays,
      (i) => baseDate.add(Duration(days: i)),
    ).where((date) => date.weekday == weekday).toList();
  }

  String _getWeekdayName(int weekday) {
    const weekdayNames = {
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Minggu',
    };
    return weekdayNames[weekday] ?? '';
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
      await _findAvailableCourt();

      if (!mounted) return;
      if (availableCourts.isEmpty) {
        showErrorSnackBar(context, 'Tidak ada lapangan yang tersedia');
      } else {
        _showBookingConfirmationDialog();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          'Terjadi kesalahan saat mengecek ketersediaan: $e',
        );
      }
      print('Error checking availability: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _findAvailableCourt() async {
    if (courts.isEmpty) {
      showErrorSnackBar(context, 'Data lapangan belum dimuat');
      return;
    }

    final startMinutes = timeToMinutes(formatTime(jamMulai));
    final endMinutes = timeToMinutes(formatTime(jamSelesai));

    availableCourts.clear();

    for (final court in courts) {
      if (await _isCourtAvailableForAllDates(
        court.courtId,
        startMinutes,
        endMinutes,
      )) {
        availableCourts.add(court);
      }
    }

    availableCourts.sort((a, b) => a.courtId.compareTo(b.courtId));

    setState(() {
      availableCourts = availableCourts;
    });
  }

  Future<bool> _isCourtAvailableForAllDates(
    String courtId,
    int startMinutes,
    int endMinutes,
  ) async {
    final List<Future<bool>> checkFutures = [];

    for (final date in selectedDates) {
      final dateStr = formatDateStr(date);
      for (
        int slotStart = startMinutes;
        slotStart < endMinutes;
        slotStart += 30
      ) {
        final slotTime = minutesToFormattedTime(slotStart);

        final futureCheck = FirebaseCheckTimeSlot().isSlotAvailable(
          courtId,
          dateStr,
          slotTime,
        );

        checkFutures.add(futureCheck);
      }
    }

    final results = await Future.wait(checkFutures);

    return results.every((result) => result); // true kalau semua available
  }

  // Validation
  bool _validateSelections() {
    if (selectedDates.isEmpty) {
      showCustomSnackBar(context, 'Pilih hari terlebih dahulu');
      return false;
    }

    if (!_isValidTimeRange(selectedStartTime, selectedEndTime)) {
      showCustomSnackBar(context, 'Jam selesai harus setelah jam mulai');
      return false;
    }

    return true;
  }

  // Dialog methods
  void _showBookingConfirmationDialog() {
    if (availableCourts.isEmpty) {
      showErrorSnackBar(context, 'Tidak ada lapangan yang tersedia');
      return;
    }

    // Reset selected courts saat dialog dibuka
    selectedCourts.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            // Gunakan StatefulBuilder
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Konfirmasi Booking'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      // Tambahkan scroll untuk content yang panjang
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Jam Mulai', selectedStartTime),
                          _buildInfoRow('Jam Selesai', selectedEndTime),

                          FutureBuilder<double>(
                            future: totalPrice(
                              startTime: selectedStartTime,
                              endTime: selectedEndTime,
                              selectedDate: selectedDates[0],
                              type: 'member',
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text('Menghitung harga...');
                              } else if (snapshot.hasError) {
                                return Text('Gagal menghitung harga');
                              } else {
                                double price = snapshot.data ?? 0;
                                price =
                                    price *
                                    selectedDates.length *
                                    selectedCourts.length;
                                return Text(
                                  'Total Harga: Rp ${price.toStringAsFixed(0)}',
                                );
                              }
                            },
                          ),
                          
                          const SizedBox(height: 16),

                          const Text(
                            'Pilih Lapangan:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // Grid layout untuk lapangan (lebih rapi untuk banyak lapangan)
                          availableCourts.isEmpty
                              ? const Center(
                                child: Text(
                                  'Tidak ada lapangan tersedia',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                              : Column(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Wrap(
                                      // Gunakan Wrap untuk layout yang lebih fleksibel
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          availableCourts.map((court) {
                                            final isSelected = selectedCourts
                                                .contains(court.courtId);

                                            return FilterChip(
                                              label: Text(
                                                court.courtId,
                                                style: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : Colors.black,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                              ),
                                              selected: isSelected,
                                              selectedColor: primaryColor,
                                              backgroundColor: Colors.grey[200],
                                              checkmarkColor: Colors.white,
                                              onSelected: (selected) {
                                                setDialogState(() {
                                                  if (selected) {
                                                    selectedCourts.add(
                                                      court.courtId,
                                                    ); // MULTI-SELECT: Tidak clear yang lain
                                                  } else {
                                                    selectedCourts.remove(
                                                      court.courtId,
                                                    );
                                                  }
                                                });
                                              },
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            // Select all available courts
                                            selectedCourts.addAll(
                                              availableCourts.map(
                                                (court) => court.courtId,
                                              ),
                                            );
                                          });
                                        },
                                        child: const Text(
                                          'Pilih Semua',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            selectedCourts.clear();
                                          });
                                        },
                                        child: const Text(
                                          'Batal Semua',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                          const SizedBox(height: 16),
                          const Text(
                            'Tanggal yang dipilih:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              itemCount: selectedDates.length,
                              itemBuilder: (context, index) {
                                final date = selectedDates[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    '${namaHari(date.weekday)}, ${DateFormat('dd MMM yyyy').format(date)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        selectedCourts.clear(); // Clear selection saat cancel
                        Navigator.of(context).pop();
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedCourts.isNotEmpty
                              ? () {
                                Navigator.of(context).pop();
                                // Pass all selected courts untuk multi-booking
                                _showUsernameInputDialogMultiple(
                                  selectedCourts.toList(),
                                );
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedCourts.isNotEmpty
                                ? primaryColor
                                : Colors.grey,
                      ),
                      child: Text(
                        'Lanjutkan',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showUsernameInputDialogMultiple(List<String> courtIds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Input Username'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Tampilkan ringkasan booking
                Text(
                  'Ringkasan Booking:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lapangan: ${courtIds.join(', ')}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Waktu: $selectedStartTime - $selectedEndTime',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Total Tanggal: ${selectedDates.length} hari',
                  style: const TextStyle(fontSize: 12),
                ),
                FutureBuilder<double>(
                  future: totalPrice(
                    startTime: formatTime(jamMulai),
                    endTime: formatTime(jamSelesai),
                    selectedDate: selectedDates[0],
                    type: 'member',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Menghitung harga...');
                    } else if (snapshot.hasError) {
                      return Text('Gagal menghitung harga');
                    } else {
                      double price = snapshot.data ?? 0;
                      price = price * selectedDates.length * courtIds.length;
                      return Text(
                        'Total Harga: Rp ${price.toStringAsFixed(0)}',
                      );
                    }
                  },
                ),

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
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
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
                  onSubmitted: (_) => _registerMemberMultipleCourts(courtIds),
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
                  _registerMemberMultipleCourts(courtIds);
                  Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => HalamanCustomers()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text(
                  'Daftarkan Member',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _registerMemberMultipleCourts(List<String> courtIds) async {
    final username = usernameController.text.trim();

    if (username.isEmpty) {
      showErrorSnackBar(context, 'Username tidak boleh kosong');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Check if user exists
      final userExists = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );
      if (!userExists) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Username tidak ditemukan');
        return;
      }

      // Book all slots for all selected courts
      await _bookAllSlotsMultipleCourts(courtIds, username);

      if (mounted) {
        showSuccessSnackBar(
          context,
          'Berhasil mendaftarkan customer sebagai member di ${courtIds.length} lapangan',
        );

        // Clear form
        usernameController.clear();
        selectedCourts.clear();
        setState(() {
          selectedWeekday = null;
          selectedDates.clear();
          availableCourts.clear();
          hasCheckedAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Gagal mendaftarkan member: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _bookAllSlotsMultipleCourts(
    List<String> courtIds,
    String username,
  ) async {
    final startMinutes = timeToMinutes(selectedStartTime);
    final endMinutes = timeToMinutes(selectedEndTime);

    List<String> bookedDates = [];
    try {
      int length = 0;
      for (final courtId in courtIds) {
        for (final date in selectedDates) {
          final dateStr = formatDateStr(date);
          bookedDates.add(dateStr);
          for (
            int minute = startMinutes;
            minute < endMinutes;
            minute += _slotDurationMinutes
          ) {
            final slotTime = minutesToFormattedTime(minute);

            await BookingMember().bookSlotForMember(
              courtId,
              dateStr,
              slotTime,
              username,
            );
            if (courtIds.first == courtId && selectedDates.first == date) {
              length++;
            }
          }
        }
      }

      await BookingMember().addTotalBookingDays(
        username,
        selectedDates.length * courtIds.length,
        length,
      );

      await BookingMember().addBookingDates(username, bookedDates);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal mendaftarkan member: $e');
    }

    // Update user role hanya sekali setelah semua booking selesai
    if (selectedDates.isNotEmpty) {
      try {
        final firstDateStr = DateFormat(
          'yyyy-MM-dd',
        ).format(selectedDates.first);
        await FirebaseUpdateUser().updateUser('role', username, 'member');
        await FirebaseUpdateUser().updateUser(
          'startTimeMember',
          username,
          firstDateStr,
        );
      } catch (e) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Gagal memperbarui peran pengguna: $e');
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const weekdayMap = {
      'Senin': 1,
      'Selasa': 2,
      'Rabu': 3,
      'Kamis': 4,
      'Jumat': 5,
      'Sabtu': 6,
      'Minggu': 7,
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
                      children:
                          weekdayMap.entries.map((entry) {
                            final isSelected = entry.value == selectedWeekday;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: primaryColor,
                                onSelected: (_) {
                                  DateTime date = DateTime.now();
                                  selectedDates = _getWeekdaysInRange(
                                    entry.value,
                                    date,
                                  );
                                  if (selectedDates.first.isBefore(date) ||
                                      selectedDates.first.isAtSameMomentAs(
                                        date,
                                      )) {
                                    date = date.add(Duration(days: 7));
                                  }
                                  setState(() {
                                    selectedWeekday = entry.value;
                                    selectedDates = _getWeekdaysInRange(
                                      entry.value,
                                      date,
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

                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: jamMulai,
                      );
                      print(picked);
                      if (picked != null) {
                        setState(() {
                          jamMulai = picked;
                          selectedStartTime = jamMulai.format(context);
                        });
                      }
                      print(selectedStartTime);
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Jam Mulai",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        controller: TextEditingController(
                          text: jamMulai.format(context),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Jam mulai harus diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: jamSelesai,
                      );
                      print(picked);
                      if (picked != null) {
                        setState(() {
                          jamSelesai = picked;
                          selectedEndTime = jamSelesai.format(context);
                        });
                      }
                      print(selectedEndTime);
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "Jam Selesai",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        controller: TextEditingController(
                          text: jamSelesai.format(context),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Jam selesai harus diisi';
                          }
                          if (isTimeValid()) {
                            return 'Jam selesai harus setelah jam mulai';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Check availability button
                  ElevatedButton(
                    onPressed: isLoading ? null : _checkAvailability,
                    // onPressed: isLoading ? null : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isLoading
                          ? 'Sedang Mencari...'
                          : 'Cek Ketersediaan & Daftarkan Member',
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
                            ...selectedDates.map(
                              (date) => Text(
                                '${_getWeekdayName(date.weekday)}, ${DateFormat('dd MMM yyyy').format(date)}',
                              ),
                            ),
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
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memproses...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
