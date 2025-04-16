import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});

  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

class _HalamanKalenderState extends State<HalamanKalender> {
  // Tanggal sekarang untuk header kalender
  DateTime selectedDate = DateTime.now();

  // Data booking (contoh data statis)
  // Di aplikasi nyata ini akan diambil dari database
  Map<String, Map<String, bool>> bookingData = {
    '01:00 - 01:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': true,
    },
    '01:30 - 02:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': true,
      'Lapangan 6': true,
    },
    '02:00 - 02:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': true,
      'Lapangan 4': true,
      'Lapangan 5': true,
      'Lapangan 6': true,
    },
    '02:30 - 03:00': {
      'Lapangan 1': true,
      'Lapangan 2': false,
      'Lapangan 3': true,
      'Lapangan 4': true,
      'Lapangan 5': true,
      'Lapangan 6': true,
    },
    '03:00 - 03:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': true,
    },
    '03:30 -04:00': {
      'Lapangan 1': false,
      'Lapangan 2': true,
      'Lapangan 3': true,
      'Lapangan 4': true,
      'Lapangan 5': false,
      'Lapangan 6': true,
    },
    '04:00 - 04:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': true,
    },
    '04:30 - 05:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': false,
      'Lapangan 6': true,
    },
    '05:00 - 05:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '05:30 - 06:00': {
      'Lapangan 1': true,
      'Lapangan 2': false,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '06:00 - 06:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': false,
      'Lapangan 6': true,
    },
    '06:30 - 07:00': {
      'Lapangan 1': true,
      'Lapangan 2': false,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': false,
      'Lapangan 6': true,
    },
    '07:00 - 07:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': false,
      'Lapangan 6': false,
    },
    '07:30 - 08:00': {
      'Lapangan 1': false,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': false,
      'Lapangan 6': false,
    },
    '08:00 - 08:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '08:30 - 09:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '09:00 - 09:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '09:30 - 10:00': {
      'Lapangan 1': false,
      'Lapangan 2': false,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': false,
      'Lapangan 6': false,
    },
    '10:00 - 10:30': {
      'Lapangan 1': true,
      'Lapangan 2': false,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '10:30 -11:00': {
      'Lapangan 1': true,
      'Lapangan 2': false,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '11:00 - 11:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '11:30 - 12:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '12:00 - 12:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '12:30 - 13:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '13:00 - 13:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '13:30 - 14:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '14:00 - 14:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '14:30 - 15:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '15:00 - 15:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '15:30 - 16:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '16:00 - 16:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '16:30 - 17:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '17:00 - 17:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '17:30 - 18:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '18:00 - 18:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '18:30 - 19:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '19:00 - 19:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '19:30 - 20:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '20:00 - 20:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '20:30 - 21:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '21:00 - 21:30': {
      'Lapangan 1': false,
      'Lapangan 2': true,
      'Lapangan 3': true,
      'Lapangan 4': true,
      'Lapangan 5': false,
      'Lapangan 6': true,
    },
    '21:30 - 22:00': {
      'Lapangan 1': true,
      'Lapangan 2': false,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '22:00 - 22:30': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
    '22:30 - 23:00': {
      'Lapangan 1': false,
      'Lapangan 2': true,
      'Lapangan 3': true,
      'Lapangan 4': false,
      'Lapangan 5': true,
      'Lapangan 6': true,
    },
    '23:00 - 23:30': {
      'Lapangan 1': true,
      'Lapangan 2': false,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': false,
      'Lapangan 6': true,
    },
    '23:30 - 24:00': {
      'Lapangan 1': true,
      'Lapangan 2': true,
      'Lapangan 3': false,
      'Lapangan 4': true,
      'Lapangan 5': true,
      'Lapangan 6': false,
    },
  };

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

  // Tampilkan dialog ketika sel diklik
  void _showBookingDialog(String time, String court, bool isBooked) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              isBooked ? 'Lapangan Sudah Dibooking' : 'Booking Lapangan',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${_formatDate(selectedDate)}'),
                Text('Waktu: $time'),
                Text('Lapangan: $court'),
                if (isBooked)
                  const Text(
                    'Status: Sudah dibooking',
                    style: TextStyle(color: Colors.red),
                  )
                else
                  const Text(
                    'Status: Tersedia',
                    style: TextStyle(color: Colors.green),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
              if (!isBooked)
                TextButton(
                  onPressed: () {
                    // Logika untuk booking lapangan
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
  Widget _buildCourtCell(String time, String court, bool isBooked) {
    return GestureDetector(
      onTap: () => _showBookingDialog(time, court, isBooked),
      child: Container(
        width: 100,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isBooked ? bookedColor : availableColor,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          isBooked ? 'Booked' : 'Available',
          style: TextStyle(
            color: isBooked ? Colors.red.shade700 : Colors.green.shade700,
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
                            _buildCourtCell(time, 'Lapangan 1', courts['Lapangan 1']!),
                            _buildCourtCell(time, 'Lapangan 2', courts['Lapangan 2']!),
                            _buildCourtCell(time, 'Lapangan 3', courts['Lapangan 3']!),
                            _buildCourtCell(time, 'Lapangan 4', courts['Lapangan 4']!),
                            _buildCourtCell(time, 'Lapangan 5', courts['Lapangan 5']!),
                            _buildCourtCell(time, 'Lapangan 6', courts['Lapangan 6']!),
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
