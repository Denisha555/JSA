import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/notification/onesignal_delete_notification.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/model/court_model.dart';
import 'package:flutter_application_1/screens_admin/price.dart';
import 'package:flutter_application_1/screens_admin/jadwal.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/screens_admin/kalender.dart';
import 'package:flutter_application_1/screens_admin/lapangan.dart';
import 'package:flutter_application_1/screens_admin/customers.dart';
import 'package:flutter_application_1/screens_admin/promo_event.dart';
import 'package:flutter_application_1/function/calender/legend_item.dart';
import 'package:flutter_application_1/services/court/firebase_get_court.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_get_time_slot.dart';

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
  String? id;

  Map<String, Map<String, Map<String, dynamic>>> bookingData = {};
  List<CourtModel> courtIds = [];

  Widget _buildCalendar(DateTime time) {
    final sortedCourtIds =
        courtIds.toList()..sort((a, b) => a.courtId.compareTo(b.courtId));

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

    return Column(
      children: [
        InteractiveViewer(
          panEnabled: true, // bisa drag ke kiri/kanan/atas/bawah
          scaleEnabled: true, // bisa pinch zoom
          minScale: 0.5,
          maxScale: 3,
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
                        ...sortedCourtIds.map(
                          (id) => _buildHeaderCell('Lapangan ${id.courtId}'),
                        ),
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
                              courts[id.courtId] ??
                              {
                                'isAvailable': true,
                                'username': '',
                                'isClosed': false,
                                'isHoliday': false,
                              };
                      
                          return _buildCourtCell(
                            time,
                            id.courtId.toString(),
                            cellData['isAvailable'] ?? true,
                            cellData['username'] ?? '',
                            cellData['type'] ?? '',
                            cellData['isClosed'] ?? false,
                            cellData['isHoliday'] ?? false,
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
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
      courtIds = await FirebaseGetCourt().getCourts(); // Load courts first

      final slots = await FirebaseGetTimeSlot().getTimeSlot(selectedDate);

      if (slots.isEmpty) {
        // Belum ada data -> generate
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);

        // Setelah generate, ambil lagi datanya
        final newSlots = await FirebaseGetTimeSlot().getTimeSlot(selectedDate);
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

  void _processBookingData(List<TimeSlotModel> slots) {
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
          'isHoliday': slot.isHoliday,
          'type': slot.type,
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
    String type,
    bool isClosed,
    bool isHoliday,
  ) {
    return Container(
      width: 120,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            isClosed
                ? closedColor
                // : (isAvailable ? availableColor : bookedColor),
                : (isAvailable
                    ? (isHoliday ? holidayColor : availableColor)
                    : bookedColor),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isClosed
                ? 'Tutup'
                : (isAvailable
                    ? (isHoliday ? 'Hari Libur' : 'Tersedia')
                    : username),
            style: TextStyle(
              color:
                  !isAvailable
                      ? type == 'member'
                          ? Colors.blue
                          : Colors.red
                      : Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
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
                onTap: () => _navigateToScreen(HalamanJadwal()),
              ),
              SizedBox(width: 5),

              _buildQuickAccessButton(
                icon: 'user',
                label: 'Customers',
                onTap: () => _navigateToScreen(HalamanCustomers()),
              ),
              _buildQuickAccessButton(
                icon: 'lapangan',
                label: "Lapangan",
                onTap: () => _navigateToScreen(HalamanLapangan()),
              ),

              SizedBox(width: 6),
              _buildQuickAccessButton(
                icon: 'booking',
                label: "Booking",
                onTap: () => _navigateToScreen(HalamanKalender()),
              ),

              SizedBox(width: 12),
              _buildQuickAccessButton(
                icon: 'harga',
                label: "Harga",
                onTap: () => _navigateToScreen(HalamanPrice()),
              ),
              SizedBox(width: 12),

              _buildQuickAccessButton(
                icon: 'promo_event',
                label: "Promo & Event",
                onTap: () => _navigateToScreen(HalamanPromoEvent()),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrCreateSlots(selectedDate);
    });

    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? adminId = prefs.getString('admin_id');
    setState(() {
      id = adminId;
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah kamu yakin ingin logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  OnesignalDeleteNotification().deleteNotification(id!);
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('admin_id');

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    // Kalau pengguna setuju untuk logout
    if (shouldLogout == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('username');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  Widget _buildStatusLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          LegendItem(label: 'Tersedia', color: availableColor),
          LegendItem(label: 'Tidak Tersedia', color: bookedColor),
          LegendItem(label: 'Hari Libur', color: holidayColor),
          LegendItem(label: 'Tutup', color: closedColor),
        ],
      ),
    );
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadOrCreateSlots(selectedDate);
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildQuickAccessMenu(context),

              const SizedBox(height: 15),

              Text(
                formatLongDate(selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusLegend(),
              _buildCalendar(selectedDate),
            ],
          ),
        ),
      ),
    );
  }
}
