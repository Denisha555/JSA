import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens_admin/customers.dart';
import 'price.dart';
import 'kalender.dart';
import 'promo_event.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/screens_admin/jadwal.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'lapangan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HalamanUtamaAdmin extends StatefulWidget {
  const HalamanUtamaAdmin({super.key});

  @override
  State<HalamanUtamaAdmin> createState() => _HalamanUtamaAdminState();
}

class _HalamanUtamaAdminState extends State<HalamanUtamaAdmin> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

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
    final sortedCourtIds =
        courtIds.toList()..sort((a, b) {
          final aNumber =
              int.tryParse(RegExp(r'\d+').stringMatch(a) ?? '') ?? 0;
          final bNumber =
              int.tryParse(RegExp(r'\d+').stringMatch(b) ?? '') ?? 0;
          return aNumber.compareTo(bNumber);
        });

    if (isLoading) {
      return const SizedBox(
        height: 200,
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
      );
    }

    if (hasError) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading data',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(errorMessage),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadOrCreateSlots(selectedDate),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildHeaderCell('Jam', width: 110),
                      ...sortedCourtIds
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
                      ...sortedCourtIds.map((id) {
                        final cellData =
                            courts[id] ?? {'isAvailable': true, 'username': '', 'isClosed': false};
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
      debugPrint('Error processing booking data: $e');
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
      print('Error loading courts: $e');
      throw Exception('Failed to load courts: $e');
    }
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

  // Widget for court cell
  Widget _buildCourtCell(
    String time,
    String court,
    bool isAvailable,
    String username,
    bool isClosed
  ) {
    return Container(
      width: 120,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isClosed 
              ? Colors.grey 
              : (isAvailable ? availableColor : bookedColor),
          border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
              isClosed 
                  ? 'Closed' 
                  : (isAvailable ? 'Available' : 'Booked'),
              style: TextStyle(
                color: isClosed 
                    ? Colors.white
                    : (isAvailable ? Colors.green.shade700 : Colors.red.shade700),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          if (!isAvailable)
            Text(
              username,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // Quick access menu buttons
  Widget _buildQuickAccessMenu(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.grey[100]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAccessButton(
                icon: 'jadwal',
                label: "Jadwal",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanJadwal(),
                    ),
                  );
                },
              ),
              SizedBox(width: 5),

              _buildQuickAccessButton(
                icon: 'user',
                label: 'Customers',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HalamanCustomers()),
                  );
                },
              ),
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

              SizedBox(width: 6),
              _buildQuickAccessButton(
                icon: 'booking',
                label: "Booking",
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HalamanKalender(),
                      ),
                    ),
              ),

              SizedBox(width: 12),
              _buildQuickAccessButton(
                icon: 'harga',
                label: "Harga",
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HalamanPrice()),
                    ),
              ),
              SizedBox(width: 12),

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
      'harga': Icons.attach_money_outlined,
      'booking': Icons.calendar_month,
      'promo_event': Icons.discount_outlined,
      'lapangan': Icons.list_alt,
      'user': Icons.person_outline,
      'jadwal': Icons.calendar_today_outlined,
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
      iconWidget = const Icon(Icons.help_outline, size: 32, color: Colors.grey);
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
    super.initState();
    // Load data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrCreateSlots(selectedDate);
    });
  }

  Future<void> _handleLogout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: _handleLogout,
              child: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: 
      RefreshIndicator(
        onRefresh: () async {
          await _loadOrCreateSlots(selectedDate);
        },
        child: 
        ListView(
          padding: const EdgeInsets.all(8),
          children: [
            _buildQuickAccessMenu(context),
            const SizedBox(height: 15),

            Column(
              children: [
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
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
              ],
            ),
            const SizedBox(height: 10),
            _buildCalendar(selectedDate),
          ],
        ),
      ),
    );
  }
}
