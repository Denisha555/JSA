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

class _HalamanKalenderState extends State<HalamanKalender> {
  // Tanggal sekarang untuk header kalender
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;

  Map<String, Map<String, bool>> bookingData = {};

  List<String> courtIds = [];

  @override
  void initState() {
    super.initState();
    _loadOrCreateSlots(selectedDate);
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

          // Legenda status
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
          isLoading
              ? const Expanded(
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
              : Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadOrCreateSlots(selectedDate);
                  },
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
                                  ...sortedCourtIds
                                      .map(
                                        (id) =>
                                            _buildHeaderCell('Lapangan $id'),
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
                                  ...sortedCourtIds
                                      .map(
                                        (id) => _buildCourtCell(
                                          time,
                                          id,
                                          courts[id]!,
                                        ),
                                      )
                                      .toList(),
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

  // Ubah tanggal
  void _changeDate(DateTime date) {
    setState(() {
      selectedDate = date;
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

  Future<void> _loadCourts() async {
    final courtsSnapshot =
        await FirebaseFirestore.instance.collection('lapangan').get();
    courtIds =
        courtsSnapshot.docs.map((doc) => doc['nomor'].toString()).toList();
  }

  void _buildBookingData(List<TimeSlot> slots) async {
    setState(() {
      isLoading = true;
    });
    Map<String, Map<String, bool>> tempdata = {};

    await _loadCourts();

    for (var slot in slots) {
      final timeRange = '${slot.startTime} - ${slot.endTime}';

      // Inisialisasi hanya jika belum ada
      if (!tempdata.containsKey(timeRange)) {
        tempdata[timeRange] = {for (var courtId in courtIds) courtId: true};
      }

      tempdata[timeRange]![slot.courtId] = slot.isAvailable;
    }

    setState(() {
      bookingData = tempdata;
      isLoading = false;
    });
  }

  void _loadOrCreateSlots(DateTime selectedDate) async {
    setState(() => isLoading = true);
    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final slots = await FirebaseService().getTimeSlotsByDate(dateStr);

    if (slots.isEmpty) {
      // Belum ada data -> generate
      await FirebaseService().generateSlotsOneDay(selectedDate);

      // Setelah generate, ambil lagi datanya
      final newSlots = await FirebaseService().getTimeSlotsByDate(dateStr);
      _buildBookingData(newSlots);
    } else {
      // Sudah ada data
      _buildBookingData(slots);
    }
  }

  Future<void> _booking(
    String startTime,
    String endTime,
    String court,
    DateTime selectedDate,
    String username,
  ) async {
    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    // Ubah startTime dan endTime jadi menit total
    int startHour = int.parse(startTime.split(':')[0]);
    int startMinute = int.parse(startTime.split(':')[1]);
    int startTotalMinutes = startHour * 60 + startMinute;

    int endHour = int.parse(endTime.split(':')[0]);
    int endMinute = int.parse(endTime.split(':')[1]);
    int endTotalMinutes = endHour * 60 + endMinute;

    // Loop setiap 30 menit
    for (
      int minutes = startTotalMinutes;
      minutes < endTotalMinutes;
      minutes += 30
    ) {
      int bookingHour = minutes ~/ 60;
      int bookingMinute = minutes % 60;
      String formattedTime =
          '${bookingHour.toString().padLeft(2, '0')}:${bookingMinute.toString().padLeft(2, '0')}';

      final formatStartTime =
          formattedTime.split(':')[0] + formattedTime.split(':')[1];
      final slotId = '${court}_${dateStr}_$formatStartTime';

      await FirebaseService().bookSlot(slotId, username);
    }
  }

  Future<void> _updateSlot(DateTime selectedDate) async {
    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    List<TimeSlot> updatedSlots = await FirebaseService().getTimeSlotsByDate(
      dateStr,
    );
    _buildBookingData(updatedSlots);
  }

  // Tampilkan dialog ketika sel diklik
  void _showBookingDialog(
    String time,
    String court,
    bool isAvailable,
    DateTime selectedDate,
  ) async {
    DateTime today = DateTime.now();
    int maxConsecutiveSlots = 1;
    String startTime = time.split(' - ')[0];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';

    // Helper untuk batas jam operasional
    bool isWithinOperatingHours(int hour, int minute) {
      int totalMinutes = hour * 60 + minute;
      return totalMinutes >= 7 * 60 && totalMinutes < 23 * 60;
    }

    if (isAvailable) {
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

        if (isNextSlotAvailable) {
          maxConsecutiveSlots = i + 1;
        } else {
          break;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        int selectedDuration = 1;
        String endTime = '';

        void updateEndTime() {
          int startHour = int.parse(startTime.split(':')[0]);
          int startMinute = int.parse(startTime.split(':')[1]);
          int totalMinutes =
              startHour * 60 + startMinute + (selectedDuration * 30);
          int endHour = totalMinutes ~/ 60;
          int endMinute = totalMinutes % 60;
          endTime =
              '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
        }

        updateEndTime();

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
                                int startHour = int.parse(
                                  startTime.split(':')[0],
                                );
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
                    if (selectedDate.isAfter(today) ||
                        (selectedDate.year == today.year &&
                            selectedDate.month == today.month &&
                            selectedDate.day == today.day))
                      TextButton(
                        onPressed: () async{
                          await _booking(
                            startTime,
                            endTime,
                            court,
                            selectedDate,
                            username,
                          );
                          await _updateSlot(selectedDate);

                          ScaffoldMessenger.of(Navigator.of(context).context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Berhasil booking Lapangan $court pada hari ${_formatDate(selectedDate)} pukul $startTime - $endTime',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Booking'),
                      ),
                ],
              ),
        );
      },
    );
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
  Widget _buildTimeCell(String time, {double width = 100}) {
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
}
