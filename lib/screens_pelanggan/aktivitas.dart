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
    _initialize(); // panggil fungsi async secara terpisah
  }

  Future<void> _initialize() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    await _fetchBookingData();
  }

  Future<void> _fetchBookingData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final allBookings = await FirebaseService().getAllBookingsByUsername(
        username,
      );

      if (!mounted) return; 
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      List<Riwayat> pastBookings = [];
      List<Terjadwal> upcomingBookings = [];

      for (var booking in allBookings) {
        DateTime bookingDate = DateTime.parse(booking.date.toString());
        String formattedDate = DateFormat('yyyy-MM-dd').format(bookingDate);

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
        } else {
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
                      onRefresh: _fetchBookingData,
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
                                            riwayat.tanggal,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            riwayat.waktu,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(riwayat.keterangan),
                                    ),
                                  );
                                },
                              ),
                    ),

                    // Terjadwal Tab
                    RefreshIndicator(
                      onRefresh: _fetchBookingData,
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
                                  final booking = terjadwals[index];
                                  return Dismissible(
                                    key: ValueKey(index),
                                    direction: DismissDirection.endToStart,
                                    background: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.red)),
                                    child: Card(
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
                                              booking.tanggal,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              booking.jam,
                                              style: const TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Text(booking.lapangan),
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
