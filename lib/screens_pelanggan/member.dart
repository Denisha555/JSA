import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/model/court_model.dart';
import 'package:flutter_application_1/function/price/price.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/court/firebase_get_court.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';
import 'package:flutter_application_1/services/booking/member/booking_member.dart';
import 'package:flutter_application_1/services/time_slot/firebase_check_time_slot.dart';
import 'package:flutter_application_1/services/notification/onesignal_send_notification.dart';

class HalamanMember extends StatefulWidget {
  const HalamanMember({super.key});

  @override
  State<HalamanMember> createState() => _HalamanMemberState();
}

class _HalamanMemberState extends State<HalamanMember> {
  DateTime now = DateTime.now();

  TimeOfDay jamMulai = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay jamSelesai = const TimeOfDay(hour: 8, minute: 0);

  List<CourtModel> courts = [];
  List<CourtModel> availableCourts = [];
  List<TimeSlotModel> availableSlots = [];
  List<String> selectedCourts = [];

  // State variables
  String selectedStartTime = '07:00';
  String selectedEndTime = '08:00';
  int? selectedWeekday;
  List<DateTime> selectedDates = [];
  bool isLoading = false;

  // Controllers
  late final TextEditingController startTimeController;
  late final TextEditingController endTimeController;

  static const int _slotDurationMinutes = 30;

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
      final loadedCourts = await FirebaseGetCourt().getCourts();
      if (mounted) {
        setState(() {
          courts = loadedCourts;
        });
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal memuat data lapangan: $e');
    }
  }

  // Business logic methods
  List<DateTime> _getWeekdaysInRange(int weekday, DateTime baseDate) {
    final endDate = DateTime(
      baseDate.year,
      baseDate.month + 1,
      0,
      baseDate.hour,
      baseDate.minute,
    );
    print("endDate : $endDate");
    final daysDifference = endDate.difference(baseDate).inDays + 1;
    print("daysDifference : $daysDifference");

    print(
      List.generate(
        daysDifference,
        (i) => baseDate.add(Duration(days: i)),
      ).where((date) => date.weekday == weekday).toList(),
    );
    return List.generate(
      daysDifference,
      (i) => baseDate.add(Duration(days: i)),
    ).where((date) => date.weekday == weekday).toList();
  }

  String _getWeekdayName(int weekday) {
    return _weekdayMap.entries
        .firstWhere(
          (entry) => entry.value == weekday,
          orElse: () => const MapEntry('', 0),
        )
        .key;
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

  bool isValidHalfHour() {
    String startMinute = selectedStartTime.split(":")[1];
    String endMinute = selectedEndTime.split(":")[1];
    return (startMinute == "00" || startMinute == "30") &&
        (endMinute == "00" || endMinute == "30");
  }

  bool isInOperationTime() {
    final start = DateFormat.Hm().parse('07:00');
    final end = DateFormat.Hm().parse('23:00');
    final selectedStart = DateFormat.Hm().parse(selectedStartTime);
    final selectedEnd = DateFormat.Hm().parse(selectedEndTime);

    return (selectedStart.isAfter(start) ||
            selectedStart.isAtSameMomentAs(start)) &&
        (selectedEnd.isBefore(end) || selectedEnd.isAtSameMomentAs(end));
  }

  // Validation methods
  bool _validateInputs() {
    if (selectedDates.isEmpty) {
      showErrorSnackBar(context, 'Pilih hari terlebih dahulu');
      return false;
    }

    final start = DateFormat.Hm().parse(selectedStartTime);
    final end = DateFormat.Hm().parse(selectedEndTime);

    if (!end.isAfter(start)) {
      showErrorSnackBar(context, 'Jam selesai harus setelah jam mulai.');
      return false;
    }

    if (!_isValidTimeRange(selectedStartTime, selectedEndTime)) {
      showErrorSnackBar(context, 'Jam selesai harus setelah jam mulai');
      return false;
    }

    if (!isInOperationTime()) {
      showErrorSnackBar(
        context,
        "Harap pilih waktu yang sesuai dengan jam operasional (07:00 - 23:00)",
      );
      return false;
    }

    if (!isValidHalfHour()) {
      showErrorSnackBar(
        context,
        'Jam booking harus dalam interval 30 menit (08:00, 08:30, 09:00, dst)',
      );
      return false;
    }

    return true;
  }

  int timeToMinutes(String time) {
    final finalTime = time.split(' ');
    final parts = finalTime[0].split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _findAvailableCourt() async {
    final getCourt = await FirebaseCheckTimeSlot().isSlotAvailable(
      courts.map((court) => court.courtId).toList(),
      selectedDates
          .map((date) => DateFormat('yyyy-MM-dd').format(date))
          .toList(),
      selectedStartTime,
      selectedEndTime,
    );

    if (getCourt.isEmpty) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Lapangan tidak tersedia');
      setState(() {
        isLoading = false;
      });
      return;
    }
    availableCourts = getCourt.toList();

    availableCourts.sort((a, b) => a.courtId.compareTo(b.courtId));

    setState(() {
      availableCourts = availableCourts;
    });
  }

  Future<void> _becomeMember(List<String> courts, List<DateTime> dates) async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';

      if (username.isEmpty) {
        throw Exception('Username tidak ditemukan');
      }

      // await _registerMemberMultipleCourts(courts);
      await _bookAllSlotsMultipleCourts(courts, username);

      if (mounted) {
        showSuccessSnackBar(context, 'Selamat! Anda berhasil menjadi member');
        Navigator.of(context).pop();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isMember', true);
        prefs.setBool('isMemberUI', true);

        await OneSignalSendNotificationAdmin().sendNewMemberNotification(
          username,
          startTimeController.text,
          courts.toString(),
          _getWeekdayName(dates.first.weekday),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Gagal menjadi member: $e');
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
    int length = 0;

    final selectedDatesStr =
        selectedDates
            .map((date) => DateFormat('yyyy-MM-dd').format(date))
            .toList();

    // Loop through each selected court
    for (final date in selectedDates) {
      for (final courtId in courtIds) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        try {
          await BookingMember().bookSlotForMember(
            courtId,
            dateStr,
            selectedStartTime,
            selectedEndTime,
            username,
          );
          if (courtIds.first == courtId && selectedDates.first == date) {
            length++;
          }
        } catch (e) {
          if (!mounted) return;
          showErrorSnackBar(context, 'Gagal memesan slot: $e');
        }
      }
    }

    try {
      print('update user data');

      final firstDateStr = DateFormat('yyyy-MM-dd').format(selectedDates.first);
      await FirebaseUpdateUser().updateUser('role', username, 'member');
      await FirebaseUpdateUser().updateUser(
        'startTimeMember',
        username,
        firstDateStr,
      );

      await BookingMember().addTotalBookingDays(
        username,
        selectedDates.length * courtIds.length,
        length,
      );

      await BookingMember().addBookingDates(
        username,
        selectedDatesStr,
        courtIds,
        selectedStartTime,
        selectedEndTime,
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal memperbarui role user: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
                                return Text('Menghitung harga...', );
                              } else if (snapshot.hasError) {
                                return Text('Gagal menghitung harga', );
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

                          const SizedBox(height: 10),

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
                                _becomeMember(selectedCourts, selectedDates);
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedCourts.isNotEmpty
                                ? primaryColor
                                : Colors.grey,
                      ),
                      child: Text(
                        'Jadi member',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _onCheckAvailability() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);

    try {
      // await _checkSlotAvailability();
      await _findAvailableCourt();

      if (!mounted) return;
      if (availableCourts.isEmpty) {
        showErrorSnackBar(context, 'Tidak ada lapangan yang tersedia');
      } else {
        _showBookingConfirmationDialog();
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool isTimeValid() {
    int startMinutes = jamMulai.hour * 60 + jamMulai.minute;
    int endMinutes = jamSelesai.hour * 60 + jamSelesai.minute;
    return startMinutes < endMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayo Jadi Member')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // _buildWeekdaySelector(),
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
                        _weekdayMap.entries.map((entry) {
                          final isSelected = entry.value == selectedWeekday;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(
                                entry.key,
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                              checkmarkColor: Colors.white,
                              selected: isSelected,
                              selectedColor: primaryColor,
                              onSelected: (_) {
                                selectedDates = _getWeekdaysInRange(
                                  entry.value,
                                  DateTime.parse(
                                    '${DateFormat('yyyy-MM-dd').format(now)} $selectedEndTime',
                                  ),
                                );
                                if (now.isAfter(selectedDates.first)) {
                                  now = now.add(Duration(days: 7));
                                }
                                setState(() {
                                  selectedWeekday = entry.value;
                                  selectedDates = _getWeekdaysInRange(
                                    entry.value,
                                    DateTime.parse(
                                      '${DateFormat('yyyy-MM-dd').format(now)} $selectedEndTime',
                                    ),
                                  );
                                  now = DateTime.now();
                                  // hasCheckedAvailability = false;
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
                      initialEntryMode: TimePickerEntryMode.inputOnly,

                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        jamMulai = picked;
                        selectedStartTime =
                            "${jamMulai.hour.toString().padLeft(2, '0')}:${jamMulai.minute.toString().padLeft(2, '0')}";

                        if (selectedWeekday != null) {
                          selectedDates = _getWeekdaysInRange(
                            selectedWeekday!,
                            DateTime.parse(
                              '${DateFormat('yyyy-MM-dd').format(now)} $selectedEndTime',
                            ),
                          );
                          if (now.isAfter(selectedDates.first)) {
                            now = now.add(Duration(days: 7));
                          }
                          setState(() {
                            selectedDates = _getWeekdaysInRange(
                              selectedWeekday!,
                              DateTime.parse(
                                '${DateFormat('yyyy-MM-dd').format(DateTime.now())} $selectedEndTime',
                              ),
                            );
                            now = DateTime.now();
                            // hasCheckedAvailability = false;
                          });
                        }
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: "Jam Mulai",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      controller: TextEditingController(
                        text:
                            "${jamMulai.hour.toString().padLeft(2, '0')}:${jamMulai.minute.toString().padLeft(2, '0')}",
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
                      initialEntryMode: TimePickerEntryMode.inputOnly,

                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        jamSelesai = picked;
                        selectedEndTime =
                            "${jamSelesai.hour.toString().padLeft(2, '0')}:${jamSelesai.minute.toString().padLeft(2, '0')}";

                        DateTime date = DateTime.now();

                        if (selectedWeekday != null) {
                          selectedDates = _getWeekdaysInRange(
                            selectedWeekday!,
                            DateTime.parse(
                              '${DateFormat('yyyy-MM-dd').format(date)} $selectedEndTime',
                            ),
                          );
                          if (date.isAfter(selectedDates.first)) {
                            date = date.add(Duration(days: 7));
                          }
                          setState(() {
                            selectedDates = _getWeekdaysInRange(
                              selectedWeekday!,
                              DateTime.parse(
                                '${DateFormat('yyyy-MM-dd').format(date)} $selectedEndTime',
                              ),
                            );
                            // hasCheckedAvailability = false;
                          });
                        }
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: "Jam Selesai",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      controller: TextEditingController(
                        text:
                            "${jamSelesai.hour.toString().padLeft(2, '0')}:${jamSelesai.minute.toString().padLeft(2, '0')}",
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

                _buildCheckButton(),

                const SizedBox(height: 20),
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
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCheckButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _onCheckAvailability,
      child: Text(isLoading ? 'Sedang Mencari...' : 'Cek Ketersediaan Waktu'),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(width: 13),
          const Text(
            'Memproses',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value', ),
    );
  }
}
