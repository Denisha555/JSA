import 'package:flutter/material.dart';
import 'price.dart';
import 'kalender.dart';
import 'promo_event.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/screens_pelanggan/masuk.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'lapangan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HalamanUtamaAdmin extends StatefulWidget {
  const HalamanUtamaAdmin({super.key});

  @override
  State<HalamanUtamaAdmin> createState() => _HalamanUtamaAdminState();
}

class _HalamanUtamaAdminState extends State<HalamanUtamaAdmin> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

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

  Widget _buildCalendar(DateTime time) {
    return Expanded(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Header row
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell('Jam', width: 100),
                      ...courtIds
                          .map((id) => _buildHeaderCell('Lapangan $id'))
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
                      ...courtIds.map((id) {
                        final cellData =
                            courts[id] ?? {'isAvailable': true, 'username': ''};
                        return _buildCourtCell(
                          time,
                          id,
                          cellData['isAvailable'] ?? true,
                          cellData['username'] ?? '',
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
    );
  }

  void _loadOrCreateSlots(DateTime selectedDate) async {
    setState(() => isLoading = true);

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
      _buildBookingData(newSlots);
    } else {
      // Sudah ada data
      _buildBookingData(slots);
    }
  }

  void _buildBookingData(List<TimeSlotForAdmin> slots) async {
    setState(() {
      isLoading = true;
    });

    Map<String, Map<String, Map<String, dynamic>>> tempdata = {};

    await _loadCourts();

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
      };
    }

    setState(() {
      bookingData = tempdata;
      isLoading = false;
    });
  }

  Future<void> _loadCourts() async {
    final courtsSnapshot =
        await FirebaseFirestore.instance.collection('lapangan').get();
    courtIds =
        courtsSnapshot.docs.map((doc) => doc['nomor'].toString()).toList();
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

  // Widget for court cell
  Widget _buildCourtCell(
    String time,
    String court,
    bool isAvailable,
    String username,
  ) {
    return Container(
      width: 120,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isAvailable ?  availableColor : bookedColor,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isAvailable ?  'Available' : 'Booked',
            style: TextStyle(
              color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          if (!isAvailable)
            Text(
              username,
              style: TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // Quick access menu buttons
  Widget _buildQuickAccessMenu(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: Colors.grey[100]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickAccessButton(
              icon: 'lapangan',
              label: "Lapangan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HalamanLapangan()),
                );
              },
            ),
            _buildQuickAccessButton(
              icon: 'price',
              label: "Harga",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HalamanPrice()),
                  ),
            ),
            _buildQuickAccessButton(
              icon: 'calender',
              label: "Kalender",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HalamanKalender()),
                  ),
            ),
            _buildQuickAccessButton(
              icon: 'promo_event',
              label: "Promo & Event",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HalamanPromoEvent(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual quick access button
  Widget _buildQuickAccessButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final iconMap = {
      'price': Icons.attach_money_outlined,
      'calender': Icons.calendar_month,
      'promo_event': Icons.discount_outlined,
      'lapangan': Icons.list_alt,
    };

    Widget iconWidget;

    // Cek apakah icon adalah path gambar
    if (icon.endsWith('.png') ||
        icon.endsWith('.jpg') ||
        icon.endsWith('.jpeg')) {
      iconWidget = Image.asset(
        icon,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
      );
    }
    // Cek apakah icon adalah key dari icon bawaan
    else if (iconMap.containsKey(icon)) {
      iconWidget = Icon(iconMap[icon], size: 32, color: Colors.black);
    }
    // Default kalau gak ketemu
    else {
      iconWidget = Icon(Icons.help_outline, size: 32, color: Colors.grey);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadOrCreateSlots(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HalamanMasuk()),
                );
              },
              child: Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickAccessMenu(context),
          const SizedBox(height: 15),
          Text(
            _formatDate(selectedDate),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
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
          _buildCalendar(selectedDate),
        ],
      ),
    );
  }
}
