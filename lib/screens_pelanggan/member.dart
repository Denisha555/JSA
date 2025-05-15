import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
// Import your availableForMember class from wherever it's defined
// import 'package:flutter_application_1/models/available_slot.dart';

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
  List<availableForMember> availableSlots = [];
  bool isLoading = false;
  bool hasCheckedAvailability = false;
  String? selectedSlotId;

  TextEditingController startTimeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();

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
      endDate.difference(baseDate).inDays + 5,
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
    List<DateTime> selectedDates, // Use string dates directly
    String startTime,
    String endTime,
  ) async {
    setState(() {
      isLoading = true;
      availableSlots = [];
    });

    try {
      List<availableForMember> allSlots = [];

      for (final date in selectedDates) {
        // Use dateStr directly since it's already in YYYY-MM-DD format
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> becomeMember(String slotId) async {
    try {
      setState(() {
        isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String username = prefs.getString('username') ?? '';

      if (username.isEmpty) {
        throw Exception('Username tidak ditemukan');
      }

      // Update user status to member
      await FirebaseService().nonMemberToMember(username);
      
      // Book the selected slot
      await FirebaseService().bookSlot(slotId, username);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selamat! Anda berhasil menjadi member'),
        ),
      );

      // Navigate to the next screen or refresh the current one
      // You might want to replace this with appropriate navigation
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menjadi member: $e'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAvailabilityDialog() {
    if (availableSlots.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ketersediaan Waktu'),
          content: const Text('Tidak ada slot tersedia untuk waktu yang Anda pilih.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ketersediaan Waktu'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableSlots.length,
            itemBuilder: (context, index) {
              final slot = availableSlots[index];
              // Parse the date string from the database format (YYYY-MM-DD)
              final date = DateFormat('yyyy-MM-dd').parse(slot.date);
              return ListTile(
                title: Text('${DateFormat('dd MMM yyyy').format(date)} (${_getWeekdayName(date.weekday)})'),
                subtitle: Text('${slot.startTime} - ${slot.endTime}'),
                selected: selectedSlotId == slot.courtId,
                onTap: () {
                  setState(() {
                    selectedSlotId = slot.courtId;
                  });
                  Navigator.of(context).pop();
                  
                  // Show confirmation dialog
                  _showConfirmationDialog(slot);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(availableForMember slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pemesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin memesan slot ini:'),
            const SizedBox(height: 10),
            // Parse the date string from the database format (YYYY-MM-DD)
            Text('Tanggal: ${slot.date}'),
            Text('Hari: ${_getWeekdayNameFromDateStr(slot.date)}'),
            Text('Waktu: ${slot.startTime} - ${slot.endTime}'),
            Text('Lapangan: ${slot.courtId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              becomeMember(slot.courtId);
            },
            child: const Text('Jadi Member'),
          ),
        ],
      ),
    );
  }

  String _getWeekdayNameFromDateStr(String dateStr) {
    // Parse the date string from the database format (YYYY-MM-DD)
    final date = DateFormat('yyyy-MM-dd').parse(dateStr);
    return _getWeekdayName(date.weekday);
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
    startTimeController.dispose();
    endTimeController.dispose();
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
                    children: weekdayMap.keys.map((day) {
                      final isSelected = weekdayMap[day] == selectedWeekday;
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
                          onSelected: (_) {
                            setState(() {
                              selectedWeekday = weekdayMap[day];
                              selectedDates = getWeekdaysInRange(
                                selectedWeekday!,
                                now,
                              );
                              
                              // Format dates as strings in "YYYY-MM-DD" format
                              selectedDatesString = selectedDates.map((date) {
                                // Ensure month and day are zero-padded (01, 02, etc.)
                                return DateFormat('yyyy-MM-dd').format(date);
                              }).toList();
                              
                              debugPrint("Selected dates: $selectedDatesString");
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
                    return generateTimeOptions().where((option) {
                      return option.contains(textEditingValue.text);
                    });
                  },
                  displayStringForOption: (option) => option,
                  onSelected: (String selection) {
                    setState(() {
                      selectedStartTime = selection;
                      startTimeController.text = selection;
                    });
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Store controller reference
                    startTimeController = fieldTextEditingController;
                    return TextField(
                      controller: fieldTextEditingController,
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
                      endTimeController.text = selection;
                    });
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Store controller reference
                    endTimeController = fieldTextEditingController;
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Pilih waktu selesai',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),

                if (hasCheckedAvailability && availableSlots.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Slot Tersedia',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...availableSlots.map((slot) {
                        // Parse the date string from the database format (YYYY-MM-DD)
                        final date = DateFormat('yyyy-MM-dd').parse(slot.date);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('${DateFormat('dd MMM yyyy').format(date)} (${_getWeekdayName(date.weekday)})'),
                            subtitle: Text('${slot.startTime} - ${slot.endTime}'),
                            trailing: ElevatedButton(
                              onPressed: () => _showConfirmationDialog(slot),
                              child: const Text('Pilih'),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (selectedStartTime == null ||
                        selectedEndTime == null ||
                        selectedDatesString.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lengkapi semua pilihan terlebih dahulu.'),
                        ),
                      );
                      return;
                    }

                    final start = DateFormat.Hm().parse(selectedStartTime!);
                    final end = DateFormat.Hm().parse(selectedEndTime!);

                    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Jam selesai harus setelah jam mulai.'),
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
                    debugPrint('Selected Start Time: $selectedStartTime');
                    debugPrint('Selected End Time: $selectedEndTime');
                    
                    if (availableSlots.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tidak ada slot tersedia untuk waktu yang Anda pilih.'),
                        ),
                      );
                    } else if (availableSlots.length == 1) {
                      // If only one slot is available, show confirmation dialog directly
                      _showConfirmationDialog(availableSlots.first);
                    } else {
                      // Show dialog to select from multiple available slots
                      _showAvailabilityDialog();
                    }
                  },
                  child: Text(isLoading ? 'Sedang Mencari...' : 'Cek Ketersediaan Waktu'),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}