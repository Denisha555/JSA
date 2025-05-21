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
  String? selectedStartTime;
  String? selectedEndTime;
  int? selectedWeekday;
  List<DateTime> selectedDates = [];
  List<String> selectedDatesString = []; // Store dates in string format
  List<AvailableForMember> availableSlots = [];
  List<AllCourts> courts = [];
  bool isLoading = false;
  bool hasCheckedAvailability = false;
  String? selectedSlotId;
  int count = 0;

  // Properly initialize controllers in initState
  late TextEditingController startTimeController;
  late TextEditingController endTimeController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers here to ensure they're always created
    startTimeController = TextEditingController();
    endTimeController = TextEditingController();
    _getCourts();
  }

  void _getCourts() async {
    List<AllCourts> tempcourts = [];
    tempcourts = await FirebaseService().getAllLapangan();
    setState(() {
      courts = tempcourts;
    });
  }

  List<String> generateTimeOptions() {
    List<String> timeOptions = [];
    DateTime startTime = DateTime(0, 1, 1, 7, 0); // 07:00
    DateTime endTime = DateTime(0, 1, 1, 23, 0); // 23:00

    while (startTime.isBefore(endTime)) {
      timeOptions.add(DateFormat.Hm().format(startTime));
      startTime = startTime.add(const Duration(minutes: 30));
    }
    return timeOptions;
  }

  List<DateTime> getWeekdaysInRange(int weekday, DateTime baseDate) {
    final endDate = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
    return List.generate(
      endDate.difference(baseDate).inDays + 1,
      (i) => baseDate.add(Duration(days: i)),
    ).where((d) => d.weekday == weekday).toList();
  }

  final Map<String, int> weekdayMap = {
    'Senin': 1,
    'Selasa': 2,
    'Rabu': 3,
    'Kamis': 4,
    'Jumat': 5,
    'Sabtu': 6,
    'Minggu': 7,
  };

  Future<void> checkAvailability(
    List<DateTime> selectedDates,
    String startTime,
    String endTime,
  ) async {
    setState(() {
      isLoading = true;
      availableSlots = [];
    });

    try {
      List<AvailableForMember> allSlots = [];

      for (final date in selectedDates) {
        final slots = await FirebaseService().getAvailableSlotsForMember(
          date,
          startTime,
          endTime,
        );
        allSlots.addAll(slots);
      }

      setState(() {
        availableSlots = allSlots;
        hasCheckedAvailability = true;
      });
    } catch (e) {
      debugPrint("Error checking availability: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> becomeMember(
    String startTime,
    String endTime, [
    String? courtId,
  ]) async {
    try {
      setState(() {
        isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String username = prefs.getString('username') ?? '';

      // Update user status to member
      await FirebaseService().nonMemberToMember(username);

      // If no courtId is provided, use the first court from the list
      final String selectedCourtId =
          courtId ?? (courts.isNotEmpty ? courts[0].courtId : '');

      if (selectedCourtId.isEmpty) {
        throw Exception('Tidak ada lapangan yang tersedia');
      }

      // Konversi jam ke menit
      int timeToMinutes(String time) {
        final parts = time.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }

      // Konversi menit ke format HH:mm
      String minutesToTime(int minutes) {
        final hours = (minutes ~/ 60).toString().padLeft(2, '0');
        final mins = (minutes % 60).toString().padLeft(2, '0');
        return '$hours$mins';
      }

      final startMinutes = timeToMinutes(startTime);
      final endMinutes = timeToMinutes(endTime);

      if (endMinutes <= startMinutes) {
        throw Exception('Jam selesai harus lebih besar dari jam mulai.');
      }

      for (var date in selectedDates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        for (int minute = startMinutes; minute < endMinutes; minute += 30) {
          final slotTime = minutesToTime(minute);
          final slotId = '${selectedCourtId}_${dateStr}_$slotTime';

          debugPrint('Booking slot: $slotId');

          await FirebaseService().bookSlot(slotId, username);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selamat! Anda berhasil menjadi member')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menjadi member: $e')));
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // void _checkSlots(String startTime, String endTime) async {
  //   if (courts.isEmpty) {
  //     _getCourts(); // Ensure courts are loaded
  //   }

  //   int timeToMinutes(String time) {
  //     final parts = time.split(':');
  //     return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  //   }

  //   int startMinutes = timeToMinutes(startTime);
  //   int endMinutes = timeToMinutes(endTime);

  //   for (final court in courts) {
  //     bool allDatesAvailable = true;

  //     for (final selectedDate in selectedDates) {
  //       for (
  //         int slotStart = startMinutes;
  //         slotStart < endMinutes;
  //         slotStart += 30
  //       ) {
  //         final slotStartStr =
  //             '${(slotStart ~/ 60).toString().padLeft(2, '0')}:${(slotStart % 60).toString().padLeft(2, '0')}';

  //         final isAvailable = await FirebaseService().isSlotAvailable(
  //           slotStartStr,
  //           court.courtId,
  //           selectedDate,
  //         );

  //         if (!isAvailable) {
  //           allDatesAvailable = false;
  //           break;
  //         }
  //       }

  //       if (!allDatesAvailable) break;
  //     }

  //     if (allDatesAvailable) {
  //       debugPrint("Lapangan ${court.courtId} tersedia di semua tanggal!");
  //       _showAvailabilityDialog(startTime, endTime, court.courtId);
  //       return;
  //     }
  //   }

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Jadwal yang dipilih tidak tersedia')),
  //   );
  // }

  Future<void> _checkSlots(String startTime, String endTime) async {
  if (courts.isEmpty) await _getCourts();

  // 1. 转换时间范围
  final timeRange = TimeRange(startTime, endTime);
  final dateStrings = selectedDates.map((d) => _formatDate(d)).toList();

  // 2. 批量获取所有需要的数据
  final allSlots = await FirebaseService().getMultiDayCourtAvailability(
    dates: dateStrings,
    timeRange: timeRange,
    courtIds: courts.map((c) => c.courtId).toList(),
  );

  // 3. 查找第一个完全可用的场地
  for (final court in courts) {
    final isAvailable = allSlots.any((slot) => 
      slot.courtId == court.courtId && 
      slot.isFullyAvailable
    );

    if (isAvailable) {
      _showAvailabilityDialog(startTime, endTime, court.courtId);
      return;
    }
  }

  _showNotAvailableSnackbar();
}

  void _showAvailabilityDialog(
    String startTime,
    String endTime,
    String courtId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detail Informasi'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lapangan : $courtId',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Jam Mulai : $startTime',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Jam Selesai : $endTime',
                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'Tanggal dipilih: ',
                    style: TextStyle(fontSize: 18),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedDates.length,
                      itemBuilder: (context, index) {
                        final date = selectedDates[index];
                        return ListTile(
                          title: Text(
                            '${_getWeekdayName(date.weekday)}, ${DateFormat('dd MMM yyyy').format(date)}',
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
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  becomeMember(startTime, endTime, courtId);
                },
                child: const Text('Jadi Member'),
              ),
            ],
          ),
    );
  }

  String _getWeekdayName(int weekday) {
    final names = weekdayMap.keys.toList();
    final values = weekdayMap.values.toList();
    final index = values.indexOf(weekday);
    if (index != -1) {
      return names[index];
    }
    return '';
  }

  @override
  void dispose() {
    // Safely dispose controllers with null checks to avoid potential errors
    if (startTimeController != null) {
      startTimeController.dispose();
    }
    if (endTimeController != null) {
      endTimeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
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
                    children:
                        weekdayMap.keys.map((day) {
                          final isSelected = weekdayMap[day] == selectedWeekday;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: ChoiceChip(
                              label: Text(
                                day,
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.blue,
                              onSelected: (_) {
                                setState(() {
                                  selectedWeekday = weekdayMap[day];
                                  selectedDates = getWeekdaysInRange(
                                    selectedWeekday!,
                                    now,
                                  );

                                  // Format dates as strings in "YYYY-MM-DD" format
                                  selectedDatesString =
                                      selectedDates.map((date) {
                                        // Ensure month and day are zero-padded (01, 02, etc.)
                                        return DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(date);
                                      }).toList();
                                });
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Pilih Jam Mulai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return generateTimeOptions().where(
                      (option) => option.contains(textEditingValue.text),
                    );
                  },
                  displayStringForOption: (option) => option,
                  onSelected: (String selection) {
                    setState(() {
                      selectedStartTime = selection;
                      startTimeController.text =
                          selection; // Update the controller's value
                    });
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Use our class-level controller instead of the provided one
                    return TextField(
                      controller: startTimeController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Pilih waktu mulai',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                const Text(
                  'Pilih Jam Selesai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return generateTimeOptions().where((option) {
                      return option.contains(textEditingValue.text);
                    });
                  },
                  displayStringForOption: (option) => option,
                  onSelected: (String selection) {
                    setState(() {
                      selectedEndTime = selection;
                      endTimeController.text =
                          selection; // Update the controller's value
                    });
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Use our class-level controller instead of the provided one
                    return TextField(
                      controller: endTimeController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Pilih waktu selesai',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (selectedStartTime == null ||
                                selectedEndTime == null ||
                                selectedDatesString.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Lengkapi semua pilihan terlebih dahulu.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final start = DateFormat.Hm().parse(
                              selectedStartTime!,
                            );
                            final end = DateFormat.Hm().parse(selectedEndTime!);

                            if (end.isBefore(start) ||
                                end.isAtSameMomentAs(start)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Jam selesai harus setelah jam mulai.',
                                  ),
                                ),
                              );
                              return;
                            }

                            await checkAvailability(
                              selectedDates,
                              selectedStartTime!,
                              selectedEndTime!,
                            );

                            debugPrint('Selected Dates: $selectedDatesString');

                            _checkSlots(selectedStartTime!, selectedEndTime!);
                          },
                  child: Text(
                    isLoading ? 'Sedang Mencari...' : 'Cek Ketersediaan Waktu',
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
