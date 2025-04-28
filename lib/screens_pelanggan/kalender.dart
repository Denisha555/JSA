import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});

  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

class _HalamanKalenderState extends State<HalamanKalender> {
  // Tanggal sekarang untuk header kalender
  DateTime selectedDate = DateTime.now();
  Map<String, Map<String, bool>> bookingData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrCreateSlots(selectedDate);
  }

  // Ubah tanggal
  void _changeDate(DateTime date) {
    setState(() {
      selectedDate = date;
      isLoading = true;
      bookingData = {}; // Clear existing data
    });
    _loadOrCreateSlots(date);
  }

  // Format tanggal untuk header
  String _formatDate(DateTime date) {
    List<String> months = [
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
    List<String> days = [
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

  void _buildBookingData(List<TimeSlot> slots) {
    Map<String, Map<String, bool>> tempData = {};

    debugPrint("Building booking data from ${slots.length} slots");

    for (var slot in slots) {
      final timeRange = '${slot.startTime} - ${slot.endTime}';

      final formattedCourtId = slot.courtId.replaceFirst(RegExp('^0+'), '');

      debugPrint(
        "Processing slot: courtId=${slot.courtId}, formattedCourtId=$formattedCourtId, time=$timeRange, isAvailable=${slot.isAvailable}",
      );

      if (!tempData.containsKey(timeRange)) {
        tempData[timeRange] = {
          'Lapangan 1': true,
          'Lapangan 2': true,
          'Lapangan 3': true,
          'Lapangan 4': true,
          'Lapangan 5': true,
          'Lapangan 6': true,
        };
      }

      // Update status - using formattedCourtId to match display format
      tempData[timeRange]!['Lapangan $formattedCourtId'] = slot.isAvailable;

      debugPrint("Updated 'Lapangan $formattedCourtId' to ${slot.isAvailable}");
    }

    setState(() {
      bookingData = tempData;
      isLoading = false;
    });
  }

  Future<void> _loadOrCreateSlots(DateTime date) async {
    setState(() {
      isLoading = true;
    });

    try {
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      debugPrint("Loading slots for date: $dateStr");

      final slots = await FirebaseService().getTimeSlotsByDate(dateStr);
      debugPrint("Retrieved ${slots.length} slots from Firestore");

      if (slots.isEmpty) {
        // No data exists - generate new slots
        debugPrint("No slots found, generating new slots for $dateStr");
        await FirebaseService().generateSlotsOneDay(date); // Pass the date

        // Fetch the newly generated slots
        final newSlots = await FirebaseService().getTimeSlotsByDate(dateStr);
        debugPrint("Generated and retrieved ${newSlots.length} new slots");
        _buildBookingData(newSlots);
      } else {
        // Data exists
        _buildBookingData(slots);
      }
    } catch (e) {
      debugPrint("Error loading slots: $e");
      setState(() {
        isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking data: $e')),
        );
      }
    }
  }

  Future<void> _booking(
    String startTime,
    String endTime,
    String court,
    DateTime selectedDate,
    String username,
  ) async {
    try {
      final dateStr =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      // Safely extract court number from string
      int? courtNumber;
      try {
        // Handle different formats of court input (e.g., "Lapangan 1" or just "1")
        if (court.contains(' ')) {
          courtNumber = int.tryParse(court.split(' ').last);
        } else {
          courtNumber = int.tryParse(court);
        }

        if (courtNumber == null) {
          throw Exception("Invalid court format: $court");
        }
      } catch (e) {
        debugPrint("Error parsing court number: $e");
        throw Exception("Could not parse court number from: $court");
      }

      // Convert start and end times to minutes safely
      int startTotalMinutes, endTotalMinutes;
      try {
        List<String> startParts = startTime.split(':');
        if (startParts.length != 2) {
          throw Exception("Invalid start time format: $startTime");
        }
        int startHour = int.parse(startParts[0]);
        int startMinute = int.parse(startParts[1]);
        startTotalMinutes = startHour * 60 + startMinute;

        List<String> endParts = endTime.split(':');
        if (endParts.length != 2) {
          throw Exception("Invalid end time format: $endTime");
        }
        int endHour = int.parse(endParts[0]);
        int endMinute = int.parse(endParts[1]);
        endTotalMinutes = endHour * 60 + endMinute;
      } catch (e) {
        debugPrint("Error parsing time: $e");
        throw Exception("Could not parse time values");
      }

      // Make sure username is not empty
      if (username.isEmpty) {
        throw Exception("Username is required for booking");
      }

      // Loop through each 30-minute slot
      for (
        int minutes = startTotalMinutes;
        minutes < endTotalMinutes;
        minutes += 30
      ) {
        int bookingHour = minutes ~/ 60;
        int bookingMinute = minutes % 60;

        String formattedTime =
            '${bookingHour.toString().padLeft(2, '0')}:${bookingMinute.toString().padLeft(2, '0')}';

        // Format court ID to match your database format (e.g., "01" instead of "1")
        String formattedCourtId = courtNumber.toString().padLeft(2, '0');

        // Format for your slot ID
        String formatStartTime = formattedTime.split(':').join('');
        String slotId =
            'Lapangan${formattedCourtId}_${dateStr}_$formatStartTime';

        debugPrint("Booking slot: $slotId for user: $username");

        // Book the slot
        await FirebaseService().bookSlot(slotId, username);
      }
    } catch (e) {
      debugPrint("Error during booking: $e");
      rethrow; // Rethrow to handle in calling function
    }
  }

  Future<void> _updateSlot(DateTime date) async {
    try {
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      debugPrint("Updating slots for date: $dateStr");

      // Clear cache to force refresh from Firestore
      List<TimeSlot> updatedSlots = await FirebaseService().getTimeSlotsByDate(
        dateStr,
      );

      debugPrint("Retrieved ${updatedSlots.length} updated slots");
      _buildBookingData(updatedSlots);
    } catch (e) {
      debugPrint("Error updating slots: $e");

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking data: $e')),
        );
      }
    }
  }

  // Display booking dialog when cell is tapped
  void _showBookingDialog(
    String time,
    String court,
    bool isAvailable,
    DateTime selectedDate,
  ) async {
    if (!isAvailable) {
      // Show who booked this slot
      _showBookingInfoDialog(time, court, selectedDate);
      return;
    }

    int maxConsecutiveSlots = 1;
    String startTime = time.split(' - ')[0];

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';

    // Check how many consecutive slots are available
    if (isAvailable) {
      List<String> startParts = startTime.split(':');
      int currentHour = int.parse(startParts[0]);
      int currentMinute = int.parse(startParts[1]);

      for (int i = 1; i <= 10; i++) {
        int nextSlotHour = currentHour;
        int nextSlotMinute = currentMinute + (30 * i);

        // Handle minute overflow
        if (nextSlotMinute >= 60) {
          nextSlotHour += nextSlotMinute ~/ 60;
          nextSlotMinute = nextSlotMinute % 60;
        }

        // Format the next time slot
        String nextTimeSlot =
            '${nextSlotHour.toString().padLeft(2, '0')}:${nextSlotMinute.toString().padLeft(2, '0')}';

        bool isNextSlotAvailable = await FirebaseService().isSlotAvailable(
          nextTimeSlot,
          court,
          selectedDate,
        );

        if (isNextSlotAvailable) {
          maxConsecutiveSlots = i + 1;
        } else {
          break; // Stop when we find a booked slot
        }
      }
    }

    // Show dialog
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        int selectedDuration = 1;
        String endTime = '';

        // Calculate initial end time
        void updateEndTime() {
          List<String> startParts = startTime.split(':');
          int startHour = int.parse(startParts[0]);
          int startMinute = int.parse(startParts[1]);

          int totalMinutes =
              startHour * 60 + startMinute + (selectedDuration * 30);
          int endHour = totalMinutes ~/ 60;
          int endMinute = totalMinutes % 60;

          endTime =
              '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
        }

        updateEndTime(); // Set initial end time

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text(
                  isAvailable ? 'Booking Lapangan' : 'Lapangan Sudah Dibooking',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tanggal: ${_formatDate(selectedDate)}'),
                    Text('Waktu mulai: $startTime'),
                    Text('Lapangan: $court'),
                    if (!isAvailable)
                      const Text(
                        'Status: Sudah dibooking',
                        style: TextStyle(color: Colors.red),
                      )
                    else ...[
                      const SizedBox(height: 16),
                      const Text('Waktu selesai:'),
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
                              selectedDuration = value!;
                              updateEndTime();
                            });
                          },
                          items:
                              List.generate(
                                maxConsecutiveSlots,
                                (i) => i + 1,
                              ).map((e) {
                                List<String> startParts = startTime.split(':');
                                int startHour = int.parse(startParts[0]);
                                int startMinute = int.parse(startParts[1]);

                                int totalMinutes =
                                    startHour * 60 + startMinute + (e * 30);
                                int endHour = totalMinutes ~/ 60;
                                int endMinute = totalMinutes % 60;

                                String formattedEndTime =
                                    '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '$formattedEndTime (${e * 30} menit)',
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                  if (isAvailable)
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog first

                        // Show loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );

                        try {
                          await _booking(
                            startTime,
                            endTime,
                            court,
                            selectedDate,
                            username,
                          );

                          // Close loading dialog
                          Navigator.pop(context);

                          // Refresh data
                          await _updateSlot(selectedDate);

                          if (!mounted) return;

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Berhasil booking Lapangan $court pada $startTime - $endTime',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          // Close loading dialog
                          Navigator.pop(context);

                          if (!mounted) return;

                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal booking: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Booking'),
                    ),
                ],
              ),
        );
      },
    );
  }

  // Show info about who booked this slot
  Future<void> _showBookingInfoDialog(
    String time,
    String court,
    DateTime date,
  ) async {
    try {
      String startTime = time.split(' - ')[0];

      if (!mounted) return;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Informasi Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal: ${_formatDate(date)}'),
                  Text('Waktu: $time'),
                  Text('Lapangan: $court'),
                  const Divider(),
                  Text('Waktu booking: $startTime'),
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
    } catch (e) {
      debugPrint("Error getting booking info: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading booking info: $e')));
    }
  }

  // Widget untuk sel header
  Widget _buildHeaderCell(String text, {double width = 100}) {
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
      ),
    );
  }

  // Widget untuk sel waktu
  Widget _buildTimeCell(String time) {
    return Container(
      width: 100,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  // Widget untuk sel lapangan
  Widget _buildCourtCell(String time, String court, bool isAvailable) {
    return GestureDetector(
      onTap: () => _showBookingDialog(time, court, isAvailable, selectedDate),
      child: Container(
        width: 100,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isAvailable ? availableColor : bookedColor,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          isAvailable ? 'Available' : 'Booked',
          style: TextStyle(
            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
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
                    ElevatedButton(
                      onPressed: () {
                        _changeDate(
                          selectedDate.subtract(const Duration(days: 1)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        _changeDate(DateTime.now());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Hari Ini'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        _changeDate(selectedDate.add(const Duration(days: 1)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Legend for status
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: availableColor,
                  margin: const EdgeInsets.only(right: 4),
                ),
                const Text('Tersedia'),
                const SizedBox(width: 16),
                Container(
                  width: 16,
                  height: 16,
                  color: bookedColor,
                  margin: const EdgeInsets.only(right: 4),
                ),
                const Text('Sudah Dibooking'),
              ],
            ),
          ),

          // Loading indicator
          if (isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading booking data...'),
                  ],
                ),
              ),
            )
          else if (bookingData.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No booking data available for this date'),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // Header row
                        Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildHeaderCell('Jam', width: 100),
                              _buildHeaderCell('Lapangan 1'),
                              _buildHeaderCell('Lapangan 2'),
                              _buildHeaderCell('Lapangan 3'),
                              _buildHeaderCell('Lapangan 4'),
                              _buildHeaderCell('Lapangan 5'),
                              _buildHeaderCell('Lapangan 6'),
                            ],
                          ),
                        ),

                        // Data rows
                        ...bookingData.entries.map((entry) {
                          final time = entry.key;
                          final courts = entry.value;

                          return Row(
                            children: [
                              _buildTimeCell(time),
                              _buildCourtCell(
                                time,
                                'Lapangan 1',
                                courts['Lapangan 1']!,
                              ),
                              _buildCourtCell(
                                time,
                                'Lapangan 2',
                                courts['Lapangan 2']!,
                              ),
                              _buildCourtCell(
                                time,
                                'Lapangan 3',
                                courts['Lapangan 3']!,
                              ),
                              _buildCourtCell(
                                time,
                                'Lapangan 4',
                                courts['Lapangan 4']!,
                              ),
                              _buildCourtCell(
                                time,
                                'Lapangan 5',
                                courts['Lapangan 5']!,
                              ),
                              _buildCourtCell(
                                time,
                                'Lapangan 6',
                                courts['Lapangan 6']!,
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Add a refresh button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _updateSlot(selectedDate),
        tooltip: 'Refresh Data',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
