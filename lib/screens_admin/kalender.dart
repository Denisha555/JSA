import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firestore_service.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});

  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

class _HalamanKalenderState extends State<HalamanKalender> {
  // Tanggal sekarang untuk header kalender
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Set<String> processingCells = {};

  Map<String, Map<String, Map<String, dynamic>>> bookingData = {};
  List<String> courtIds = [];
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

  void _changeDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadOrCreateSlots(date);
  }

  // Show dialog to add a new booking
  void _showAddBookingDialog(String time, String court) async {
    final TextEditingController usernameController = TextEditingController();
    String startTime = time.split(' - ')[0];
    int maxConsecutiveSlots = 1;

    bool isWithinOperatingHours(int hour, int minute) {
      int totalMinutes = hour * 60 + minute;
      return totalMinutes >= 7 * 60 && totalMinutes < 23 * 60;
    }

    int currentHour = int.parse(time.split(':')[0]);
    int currentMinute = int.parse(time.split(':')[1].split(' ')[0]);

    int startTotalMinutes = currentHour * 60 + currentMinute;
    int remainingMinutes = (23 * 60) - startTotalMinutes;
    int maxPossibleSlots = remainingMinutes ~/ 30;

    for (int i = 1; i <= maxPossibleSlots; i++) {
      int nextTotalMinutes = startTotalMinutes + (i * 30);
      int nextSlotHour = nextTotalMinutes ~/ 60;
      int nextSlotMinute = nextTotalMinutes % 60;

      if (!isWithinOperatingHours(nextSlotHour, nextSlotMinute)) {
        break;
      }

      String nextTimeSlot =
          '${nextSlotHour.toString().padLeft(2, '0')}:${nextSlotMinute.toString().padLeft(2, '0')}';

      bool isNextSlotAvailable = await FirebaseService().isSlotAvailable(
        nextTimeSlot,
        court,
        selectedDate,
      );

      bool isNextSlotClosed = await FirebaseService().isSlotClosed(
        nextTimeSlot,
        court,
        selectedDate,
      );

      if (isNextSlotAvailable && !isNextSlotClosed) {
        maxConsecutiveSlots = i + 1;
      } else {
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        int selectedDuration = 1;

        void updateEndTime() {
          int startHour = int.parse(startTime.split(':')[0]);
          int startMinute = int.parse(startTime.split(':')[1]);
          int totalMinutes =
              startHour * 60 + startMinute + (selectedDuration * 30);
          int endHour = totalMinutes ~/ 60;
          int endMinute = totalMinutes % 60;
          String endTime =
              '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
        }

        updateEndTime();

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text('Add New Booking'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Court $court'),
                    Text('Start Time: $startTime'),
                    Text('End Time: '),
                    DropdownButton<int>(
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
                          List.generate(maxConsecutiveSlots, (i) => i + 1).map((
                            e,
                          ) {
                            int startHour = int.parse(startTime.split(':')[0]);
                            int startMinute = int.parse(
                              startTime.split(':')[1],
                            );
                            int totalMinutes =
                                startHour * 60 + startMinute + (e * 30);
                            int endHour = totalMinutes ~/ 60;
                            int endMinute = totalMinutes % 60;
                            String formattedEndTime =
                                '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

                            return DropdownMenuItem(
                              value: e,
                              child: Text(formattedEndTime),
                            );
                          }).toList(),
                    ),

                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 2.0,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: primaryColor,
                        ),
                        labelText: "Username",
                        labelStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 20.0,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (usernameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Silahkan inputkan nama customer'),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        bookingData[time]![court]!['isAvailable'] = false;
                        bookingData[time]![court]!['username'] =
                            usernameController.text;
                      });

                      bool user = await FirebaseService().checkUser(
                        usernameController.text,
                      );

                      if (user) {
                        // await FirebaseService().bookSlotForNonMember(slotId, usernameController.text, totalHours)
                        // TODO : book slot for non member
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Username tidak ditemukan, silahkan lakukan pendaftaran terlebih dahulu'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
        );
      },
    );
  }

  Future<void> _loadOrCreateSlots(DateTime selectedDate) async {
    // Set loading state first thing
    if (mounted) {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = '';
      });
    }

    try {
      await _loadCourts(); // Load courts first

      final slots = await FirebaseService().getTimeSlotsByDateForAdmin(
        selectedDate,
      );

      if (slots.isEmpty) {
        // Belum ada data -> generate
        await FirebaseService().generateSlotsOneDay(selectedDate);

        // Setelah generate, ambil lagi datanya
        final newSlots = await FirebaseService().getTimeSlotsByDateForAdmin(
          selectedDate,
        );
        _processBookingData(newSlots);
      } else {
        // Sudah ada data
        _processBookingData(slots);
      }
    } catch (e) {
      debugPrint('Error loading slots: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading slots: $e')));
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  void _processBookingData(List<TimeSlotForAdmin> slots) {
    try {
      Map<String, Map<String, Map<String, dynamic>>> tempdata = {};

      for (var slot in slots) {
        final timeRange = '${slot.startTime} - ${slot.endTime}';

        // Inisialisasi timeRange jika belum ada
        if (!tempdata.containsKey(timeRange)) {
          tempdata[timeRange] = {};
        }

        // Isi data per lapangan
        tempdata[timeRange]![slot.courtId] = {
          'isAvailable': slot.isAvailable,
          'username': slot.username,
          'isClosed': slot.isClosed,
        };
      }

      if (mounted) {
        setState(() {
          bookingData = tempdata;
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing booking data: $e')),
      );
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCourts() async {
    try {
      final courtsSnapshot =
          await FirebaseFirestore.instance.collection('lapangan').get();
      courtIds =
          courtsSnapshot.docs.map((doc) => doc['nomor'].toString()).toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading courts: $e')));
      throw Exception('Failed to load courts: $e');
    }
  }

  // Show booking details
  void _showBookingDetails(String time, String court, String username) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Booking Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time: $time'),
                Text('Court: $court'),
                Text('Customer: $username'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editBooking(time, court, username);
                },
                child: Text('Edit'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    bookingData[time]![court]!['isAvailable'] = true;
                    bookingData[time]![court]!['username'] = '';
                  });
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Cancel Booking'),
              ),
            ],
          ),
    );
  }

  // Edit booking
  void _editBooking(String time, String court, String currentUsername) {
    final TextEditingController nameController = TextEditingController(
      text: currentUsername,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Time: $time'),
                Text('Court: $court'),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Customer Name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Silahkan inputkan nama customers'),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    bookingData[time]![court]!['username'] =
                        nameController.text;
                  });

                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  // Widget for header cell
  Widget _buildHeaderCell(String text, {double width = 120}) {
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

  // Widget for time cell
  Widget _buildTimeCell(String time) {
    return Container(
      width: 110,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  bool _isTimePast(String timeSlot, DateTime date) {
    try {
      debugPrint("Cek timeSlot: $timeSlot"); // debug
      final now = DateTime.now();
      final startTime = timeSlot.split(' - ')[0];
      final hour = int.parse(startTime.split(':')[0]);
      final minute = int.parse(startTime.split(':')[1]);

      final slotDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      debugPrint("Now: $now | Slot: $slotDateTime"); // debug

      return slotDateTime.isBefore(now);
    } catch (e) {
      debugPrint("Error parsing timeSlot: $e");
      return false;
    }
  }

  // Generate unique key for each cell to track processing state
  String _getCellKey(String time, String court) {
    return '${time}_$court';
  }

  // Widget for court cell
  Widget _buildCourtCell(
    String time,
    String court,
    bool isAvailable,
    String username,
    bool isClosed,
  ) {
    // Cek apakah waktu ini sudah lewat
    bool isPast = _isTimePast(time, selectedDate);

    // Key unik untuk cell
    String cellKey = _getCellKey(time, court);
    bool isProcessing = processingCells.contains(cellKey);

    void handleTap() async {
      if (isProcessing) return;

      if (isPast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Waktu ini sudah lewat, tidak bisa dibooking'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (isClosed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lapangan ditutup pada waktu ini'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Tandai cell sedang diproses
      setState(() {
        processingCells.add(cellKey);
      });

      try {
        if (!isAvailable) {
          _showBookingDetails(time, court, username);
        } else {
          _showAddBookingDialog(time, court);
        }
      } finally {
        // Hapus dari daftar proses
        setState(() {
          processingCells.remove(cellKey);
        });
      }
    }

    return GestureDetector(
      onTap: handleTap,
      child: Container(
        width: 120,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              isClosed
                  ? Colors.grey
                  : (isAvailable ? availableColor : bookedColor),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child:
            isProcessing
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isClosed
                          ? 'Tutup'
                          : (isAvailable ? 'Tersedia' : 'Telah Dibooking'),
                      style: TextStyle(
                        color:
                            isClosed
                                ? Colors.white
                                : (isAvailable
                                    ? Colors.green.shade700
                                    : Colors.red.shade700),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    if (!isAvailable && !isClosed)
                      Text(
                        username,
                        style: TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrCreateSlots(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedCourtIds =
        courtIds.toList()..sort((a, b) {
          final aNumber =
              int.tryParse(RegExp(r'\d+').stringMatch(a) ?? '') ?? 0;
          final bNumber =
              int.tryParse(RegExp(r'\d+').stringMatch(b) ?? '') ?? 0;
          return aNumber.compareTo(bNumber);
        });
    return Scaffold(
      appBar: AppBar(title: Text("Kalender")),
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

          // Legenda status
          Padding(
            padding: const EdgeInsets.only(top: 15),
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
                const Text('Telah Dibooking'),
                const SizedBox(width: 16),
                Container(
                  width: 16,
                  height: 16,
                  color: closedColor,
                  margin: const EdgeInsets.only(right: 4),
                ),
                const Text('Tutup'),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading booking data...'),
                        ],
                      ),
                    )
                    // Header row
                    : RefreshIndicator(
                      onRefresh: () async {
                        _loadOrCreateSlots(selectedDate);
                      },
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
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
                                      _buildHeaderCell('Jam', width: 110),
                                      ...sortedCourtIds
                                          .map(
                                            (id) => _buildHeaderCell(
                                              'Lapangan $id',
                                            ),
                                          )
                                          .toList(),
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
                                      ...sortedCourtIds.map((id) {
                                        final cellData =
                                            courts[id] ??
                                            {
                                              'isAvailable': true,
                                              'username': '',
                                              'isClosed': false,
                                            };
                                        return _buildCourtCell(
                                          time,
                                          id,
                                          cellData['isAvailable'] ?? true,
                                          cellData['username'] ?? '',
                                          cellData['isClosed'] ?? false,
                                        );
                                      }).toList(),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
