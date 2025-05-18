import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:intl/intl.dart';

class Riwayat {
  final String tanggal;
  final String keterangan;
  final String waktu;

  Riwayat({
    required this.tanggal,
    required this.keterangan,
    required this.waktu,
  });
}

class Terjadwal {
  final String tanggal;
  final String jam;
  final String lapangan;

  Terjadwal({required this.tanggal, required this.jam, required this.lapangan});
}

class HalamanAktivitas extends StatefulWidget {
  const HalamanAktivitas({super.key});

  @override
  State<HalamanAktivitas> createState() => _HalamanAktivitasState();
}

class _HalamanAktivitasState extends State<HalamanAktivitas> {
  List<Riwayat> riwayats = [];
  List<Terjadwal> terjadwals = [];
  bool isLoading = true;
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    _fetchBookingData();
  }

  Future<void> _fetchBookingData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all bookings for the user (past and upcoming)
      final allBookings = await FirebaseService().getAllBookingsByUsername(
        username,
      );

      // Today's date for comparison
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      List<Riwayat> pastBookings = [];
      List<Terjadwal> upcomingBookings = [];

      for (var booking in allBookings) {
        // Parse the booking date
        DateTime bookingDate;

        bookingDate = DateTime.parse(booking.date.toString());

        // Format date for display
        String formattedDate = DateFormat('yyyy-MM-dd').format(bookingDate);

        // For past bookings (including today's completed bookings)
        if (bookingDate.isBefore(today) ||
            (bookingDate.isAtSameMomentAs(today) &&
                _isTimeInPast(booking.startTime))) {
          pastBookings.add(
            Riwayat(
              tanggal: formattedDate,
              keterangan: "Lapangan ${booking.courtId} Berhasil Terbooking",
              waktu: '${booking.startTime} - ${booking.endTime}',
            ),
          );
        }
        // For upcoming bookings
        else {
          upcomingBookings.add(
            Terjadwal(
              tanggal: formattedDate,
              jam: '${booking.startTime} - ${booking.endTime}',
              lapangan: "Lapangan ${booking.courtId}",
            ),
          );
        }
      }

      setState(() {
        riwayats = pastBookings;
        terjadwals = upcomingBookings;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching booking data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to check if a time is in the past
  bool _isTimeInPast(String timeString) {
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');
    final bookingTime = timeFormat.parse(timeString);

    final bookingDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      bookingTime.hour,
      bookingTime.minute,
    );

    return bookingDateTime.isBefore(now);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Aktivitas"),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [Tab(text: "Riwayat"), Tab(text: "Terjadwal")],
          ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  children: [
                    // Riwayat Tab
                    RefreshIndicator(
                      onRefresh: () async {
                        await _fetchBookingData();
                      },
                      child:
                          riwayats.isEmpty
                              ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 200),
                                  Center(
                                    child: Text("Tidak ada riwayat pemesanan"),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: riwayats.length,
                                itemBuilder: (context, index) {
                                  final riwayat = riwayats[index];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      title: Row(
                                        children: [
                                          Text(
                                            riwayats[index].tanggal,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            riwayats[index].waktu,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        riwayats[index].keterangan,
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),

                    // Terjadwal Tab
                    RefreshIndicator(
                      onRefresh: () async {
                        await _fetchBookingData(); // ← Diperbaiki: pakai tanda kurung
                      },
                      child:
                          terjadwals.isEmpty
                              ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 200),
                                  Center(
                                    child: Text(
                                      "Tidak ada jadwal pemesanan mendatang",
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: terjadwals.length,
                                itemBuilder: (context, index) {
                                  final jadwal = terjadwals[index];
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.schedule,
                                        color: Colors.blue,
                                      ),
                                      title: Row(
                                        children: [
                                          Text(
                                            terjadwals[index].tanggal,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            terjadwals[index].jam,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        terjadwals[index].lapangan,
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }
}
