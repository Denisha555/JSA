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

// Helper class untuk menggabung booking
class BookingGroup {
  final String date;
  final String courtId;
  final List<String> timeSlots;

  BookingGroup({
    required this.date,
    required this.courtId,
    required this.timeSlots,
  });

  String get combinedTimeRange {
    if (timeSlots.isEmpty) return '';

    // Sort time slots untuk memastikan urutan yang benar
    timeSlots.sort((a, b) {
      final timeA = a.split(' - ')[0];
      final timeB = b.split(' - ')[0];
      return timeA.compareTo(timeB);
    });

    final startTime = timeSlots.first.split(' - ')[0];
    final endTime = timeSlots.last.split(' - ')[1];

    return '$startTime - $endTime';
  }
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
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    await _fetchBookingData();
  }

  // Fungsi untuk menggabung booking yang berurutan
  List<BookingGroup> _groupConsecutiveBookings(List<dynamic> bookings) {
    if (bookings.isEmpty) return [];

    // Group bookings by date and court
    Map<String, Map<String, List<String>>> groupedBookings = {};

    for (var booking in bookings) {
      String date = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(booking.date.toString()));
      String courtId = booking.courtId.toString();
      String timeSlot = '${booking.startTime} - ${booking.endTime}';

      groupedBookings[date] ??= {};
      groupedBookings[date]![courtId] ??= [];
      groupedBookings[date]![courtId]!.add(timeSlot);
    }

    List<BookingGroup> result = [];

    groupedBookings.forEach((date, courts) {
      courts.forEach((courtId, timeSlots) {
        // Sort time slots
        timeSlots.sort((a, b) {
          final timeA = a.split(' - ')[0];
          final timeB = b.split(' - ')[0];
          return timeA.compareTo(timeB);
        });

        // Group consecutive time slots
        List<String> currentGroup = [];
        String? lastEndTime;

        for (String timeSlot in timeSlots) {
          String startTime = timeSlot.split(' - ')[0];
          String endTime = timeSlot.split(' - ')[1];

          if (lastEndTime == null || lastEndTime == startTime) {
            // This is consecutive or the first slot
            if (currentGroup.isEmpty) {
              currentGroup.add(timeSlot);
            } else {
              // Update the end time of the group
              String groupStartTime = currentGroup.first.split(' - ')[0];
              currentGroup = ['$groupStartTime - $endTime'];
            }
            lastEndTime = endTime;
          } else {
            // Not consecutive, start a new group
            result.add(
              BookingGroup(
                date: date,
                courtId: courtId,
                timeSlots: List.from(currentGroup),
              ),
            );
            currentGroup = [timeSlot];
            lastEndTime = endTime;
          }
        }

        // Add the last group
        if (currentGroup.isNotEmpty) {
          result.add(
            BookingGroup(date: date, courtId: courtId, timeSlots: currentGroup),
          );
        }
      });
    });

    return result;
  }

  // Fungsi untuk membatalkan booking
  Future<void> _cancelBooking(
    String date,
    String courtId,
    String timeRange,
  ) async {
    try {
      // Tampilkan dialog konfirmasi
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Konfirmasi Pembatalan'),
            content: Text(
              'Apakah Anda yakin ingin membatalkan booking?\n\n'
              'Tanggal: $date\n'
              'Lapangan: $courtId\n'
              'Waktu: $timeRange',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Ya, Batalkan'),
              ),
            ],
          );
        },
      );

      // Jika user batal (false) atau keluar (null), hentikan
      if (shouldCancel != true) return;

      final timesToCancel = _parseTimeRange(timeRange);

      for (final timeSlot in timesToCancel) {
        final times = timeSlot.split(' - ');
        if (times.length != 2) continue; // validasi format waktu

        final startTime = times[0].trim();
        final endTime = times[1].trim();

        await FirebaseService().cancelBooking(
          username,
          date,
          courtId,
          startTime,
          endTime,
        );
      }

      // Beri notifikasi sukses
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh data setelah pembatalan
      await _fetchBookingData();
    } catch (e) {
      debugPrint('Error canceling booking: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat membatalkan booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function to parse time range back to individual slots
  List<String> _parseTimeRange(String timeRange) {
    List<String> times = timeRange.split(' - ');
    String startTime = times[0];
    String endTime = times[1];

    List<String> timeSlots = [];
    DateTime start = DateFormat('HH:mm').parse(startTime);
    DateTime end = DateFormat('HH:mm').parse(endTime);

    DateTime current = start;
    while (current.isBefore(end)) {
      DateTime next = current.add(const Duration(minutes: 30));
      String currentStr = DateFormat('HH:mm').format(current);
      String nextStr = DateFormat('HH:mm').format(next);
      timeSlots.add('$currentStr - $nextStr');
      current = next;
    }

    return timeSlots;
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

      List<dynamic> pastBookingsList = [];
      List<dynamic> upcomingBookingsList = [];

      // Separate past and upcoming bookings
      for (var booking in allBookings) {
        DateTime bookingDate = DateTime.parse(booking.date.toString());

        if (bookingDate.isBefore(today) ||
            (bookingDate.isAtSameMomentAs(today) &&
                _isTimeInPast(booking.startTime))) {
          pastBookingsList.add(booking);
        } else {
          upcomingBookingsList.add(booking);
        }
      }

      // Group consecutive bookings
      List<BookingGroup> pastGroups = _groupConsecutiveBookings(
        pastBookingsList,
      );
      List<BookingGroup> upcomingGroups = _groupConsecutiveBookings(
        upcomingBookingsList,
      );

      // Convert to display format
      List<Riwayat> pastBookings =
          pastGroups
              .map(
                (group) => Riwayat(
                  tanggal: group.date,
                  keterangan: "Lapangan ${group.courtId}",
                  waktu: group.combinedTimeRange,
                ),
              )
              .toList();

      List<Terjadwal> upcomingBookings =
          upcomingGroups
              .map(
                (group) => Terjadwal(
                  tanggal: group.date,
                  jam: group.combinedTimeRange,
                  lapangan: "Lapangan ${group.courtId}",
                ),
              )
              .toList();

      // Sort by date and time
      pastBookings.sort((a, b) {
        int dateCompare = b.tanggal.compareTo(
          a.tanggal,
        ); // Newest first for history
        if (dateCompare != 0) return dateCompare;
        return a.waktu.compareTo(b.waktu);
      });

      upcomingBookings.sort((a, b) {
        int dateCompare = a.tanggal.compareTo(
          b.tanggal,
        ); // Earliest first for scheduled
        if (dateCompare != 0) return dateCompare;
        return a.jam.compareTo(b.jam);
      });

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
                                padding: const EdgeInsets.all(10),
                                itemCount: terjadwals.length,
                                itemBuilder: (context, index) {
                                  final booking = terjadwals[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Dismissible(
                                      key: ValueKey(
                                        '${booking.tanggal}_${booking.lapangan}_${booking.jam}',
                                      ),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        // Extract court number from lapangan string (e.g., "Lapangan 1" -> "1")
                                        String courtId = booking.lapangan
                                            .replaceAll('Lapangan ', '');

                                        await _cancelBooking(
                                          booking.tanggal,
                                          courtId,
                                          booking.jam,
                                        );
                                        return false; // Don't actually dismiss, let the refresh handle the UI update
                                      },
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.red,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: const [
                                            Icon(
                                              Icons.cancel,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Batal',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
