import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:intl/intl.dart'; // Add for date formatting

class Riwayat {
  final String tanggal;
  final String keterangan;
  
  Riwayat({required this.tanggal, required this.keterangan});
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

  void _fetchBookingData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get all bookings for the user (past and upcoming)
      final allBookings = await FirebaseService().getAllBookingsByUsername(username);
      
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
            (bookingDate.isAtSameMomentAs(today) && _isTimeInPast(booking.startTime))) {
          pastBookings.add(
            Riwayat(
              tanggal: formattedDate,
              keterangan: "Lapangan ${booking.courtId} Berhasil Terbooking",
            ),
          );
        } 
        // For upcoming bookings
        else {
          upcomingBookings.add(
            Terjadwal(
              tanggal: formattedDate,
              jam: booking.startTime,
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
            tabs: [
              Tab(text: "Riwayat"),
              Tab(text: "Terjadwal"),
            ],
          ),
        ),
        body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                // Riwayat Tab
                riwayats.isEmpty
                  ? const Center(child: Text("Tidak ada riwayat pemesanan"))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: riwayats.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.check_circle, color: Colors.green),
                              title: Text(
                                riwayats[index].tanggal,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(riwayats[index].keterangan),
                            ),
                          );
                        },
                      ),
                    ),
                
                // Terjadwal Tab
                terjadwals.isEmpty
                  ? const Center(child: Text("Tidak ada jadwal pemesanan mendatang"))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: terjadwals.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.schedule, color: Colors.blue),
                              title: Row(
                                children: [
                                  Text(
                                    terjadwals[index].tanggal,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    terjadwals[index].jam,
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                              subtitle: Text(terjadwals[index].lapangan),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () {
                                  // Option to add to calendar or view details
                                  _showBookingDetails(terjadwals[index]);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              ],
            ),
        // You could add a refresh button here
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchBookingData,
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
  
  void _showBookingDetails(Terjadwal booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Jadwal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${booking.tanggal}'),
            Text('Jam: ${booking.jam}'),
            Text('Lokasi: ${booking.lapangan}'),
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
  }
}