import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/firestore_service.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});

  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

class _HalamanKalenderState extends State<HalamanKalender> {
  // Tanggal sekarang untuk header kalender
  DateTime selectedDate = DateTime.now();

  Map<String, Map<String, bool>> bookingData = {};

  @override
  void initState() {
    super.initState();
    _loadOrCreateSlots(selectedDate);
  }

  // Ubah tanggal
  void _changeDate(DateTime date) {
    setState(() {
      selectedDate = date;
      // Dalam aplikasi nyata, kita akan memuat data booking baru sesuai tanggal
    });
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
    Map<String, Map<String, bool>> tempdata = {};
    for (var slot in slots) {
      final timeRange = '${slot.startTime} - ${slot.endTime}';
      if (!tempdata.containsKey(timeRange)) {
        // Kalau jam belum ada, inisialisasi semua lapangan
        tempdata[timeRange] = {
          'Lapangan 1': true,
          'Lapangan 2': true,
          'Lapangan 3': true,
          'Lapangan 4': true,
          'Lapangan 5': true,
          'Lapangan 6': true,
        };
      }
      // Update status berdasarkan courtId
      tempdata[timeRange]!['Lapangan ${slot.courtId}'] = slot.isAvailable;
    }
    // Set ke state
    setState(() {
      bookingData = tempdata;
    });
  }

  void _loadOrCreateSlots(DateTime selectedDate) async {
    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final slots = await FirebaseService().getTimeSlotsByDate(dateStr);

    if (slots.isEmpty) {
      // Belum ada data -> generate
      await FirebaseService().generateSlots1day();

      // Setelah generate, ambil lagi datanya
      final newSlots = await FirebaseService().getTimeSlotsByDate(dateStr);
      _buildBookingData(newSlots);
    } else {
      // Sudah ada data
      _buildBookingData(slots);
    }
  }

  // Tampilkan dialog ketika sel diklik
  void _showBookingDialog(
    String time,
    String court,
    bool isAvaible,
    DateTime selectedDate,
  ) async {
    int maxConsecutiveSlots = 1; // Start with at least 1 slot (current time)
    String startTime = time.split(' - ')[0];
    court = court.split(' ')[1].padLeft(2, '0');

    if (isAvaible) {
      // Parse the current time slot to determine next slots
      int currentHour = int.parse(time.split(':')[0]);
      int currentMinute = int.parse(time.split(':')[1].split(' ')[0]);

      // Check next time slots (assuming 30-minute increments)
      for (int i = 1; i <= 4; i++) {
        int nextSlotHour = currentHour;
        int nextSlotMinute = currentMinute + (30 * i);

        // Handle minute overflow
        if (nextSlotMinute >= 60) {
          nextSlotHour += nextSlotMinute ~/ 60;
          nextSlotMinute = nextSlotMinute % 60;
        }

        // Format the next time slot
        String nextTimeSlot =
            '$nextSlotHour:${nextSlotMinute.toString().padLeft(2, '0')}';

        // Check if the next slot is available (you need to implement this logic)
        bool isNextSlotAvailable = await FirebaseService().isSlotAvailable(
          nextTimeSlot,
          court,
          selectedDate,
        );

        if (isNextSlotAvailable) {
          maxConsecutiveSlots = i + 1;
        } else {
          break; // Stop checking if a slot is unavailable
        }
      }
    }

    int selectedDuration = 1;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              isAvaible ? 'Booking Lapangan' : 'Lapangan Sudah Dibooking',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${_formatDate(selectedDate)}'),
                Text('Waktu mulai: $startTime'),
                Text('Lapangan: $court'),
                if (!isAvaible)
                  const Text(
                    'Status: Sudah dibooking',
                    style: TextStyle(color: Colors.red),
                  )
                else ...[
                  const SizedBox(height: 16),
                  const Text('Durasi:'),
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
                      underline: Container(), // Remove the default underline
                      onChanged: (value) {
                        setState(() {
                          // Update the StatefulBuilder state
                          selectedDuration = value!;
                        });
                      },
                      items:
                          List.generate(maxConsecutiveSlots, (i) => i + 1).map((
                            e,
                          ) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text('${e * 30} menit'),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Durasi maksimal: ${maxConsecutiveSlots * 30} menit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
              if (isAvaible)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Berhasil booking $court pada $time'),
                      ),
                    );
                  },
                  child: Text('Booking'),
                ),
            ],
          ),
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
  Widget _buildCourtCell(String time, String court, bool isAvaible) {
    return GestureDetector(
      onTap: () => _showBookingDialog(time, court, isAvaible, selectedDate),
      child: Container(
        width: 100,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isAvaible ? availableColor : bookedColor,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          isAvaible ? 'Available' : 'Booked',
          style: TextStyle(
            color: isAvaible ? Colors.green.shade700 : Colors.red.shade700,
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
    );
  }
}
