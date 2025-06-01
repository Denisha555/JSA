import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:intl/intl.dart';

// Data Models
class Riwayat {
  final String tanggal;
  final String keterangan;
  final String waktu;
  final String type;

  Riwayat({
    required this.tanggal,
    required this.keterangan,
    required this.waktu,
    required this.type,
  });
}

class Terjadwal {
  final String tanggal;
  final String jam;
  final String lapangan;
  final String type;

  Terjadwal({
    required this.tanggal,
    required this.jam,
    required this.lapangan,
    required this.type,
  });
}

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

class _HalamanAktivitasState extends State<HalamanAktivitas>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Riwayat> riwayats = [];
  List<Terjadwal> terjadwals = [];
  bool isLoading = true;
  String username = '';
  bool isMember = false;

  // Constants
  static const List<String> daftarHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  bool get wantKeepAlive => false; // Tidak keep alive agar selalu fresh

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Lifecycle observer untuk detect ketika app kembali ke foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && mounted) {
      // App kembali ke foreground, refresh data
      _fetchBookingData();
    }
  }

  // Auto refresh setiap kali widget di-build ulang (misal dari navigation)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Refresh data jika sudah pernah di-initialize sebelumnya
    if (username.isNotEmpty) {
      _fetchBookingData();
    }
  }

  // Initialization Methods
  Future<void> _initialize() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';

    await _fetchBookingData();
  }

  // Enhanced Booking Data Methods dengan loading indicator yang lebih smooth
  Future<void> _fetchBookingData() async {
    if (!mounted) return;

    // Hanya show loading di awal atau kalau data kosong
    if (riwayats.isEmpty && terjadwals.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      final allBookings = await FirebaseService().getAllBookingsByUsername(
        username,
      );
      if (!mounted) return;

      // FIX: Set isMember lebih awal dan dengan pengecekan yang lebih robust
      bool memberStatus = false;
      if (allBookings.isNotEmpty) {
        // Cek semua booking untuk memastikan status member
        memberStatus = allBookings.any(
          (booking) => booking.type?.toString().toLowerCase() == 'member',
        );
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final (pastBookings, upcomingBookings) = _separateBookings(
        allBookings,
        today,
      );

      final pastGroups = _groupConsecutiveBookings(pastBookings);
      final upcomingGroups = _groupConsecutiveBookings(upcomingBookings);

      setState(() {
        // Set isMember dulu sebelum convert data
        isMember = memberStatus;
        riwayats = _convertToRiwayat(pastGroups);
        terjadwals = _convertToTerjadwal(upcomingGroups);
        isLoading = false;
      });

      // Debug log untuk monitoring
      debugPrint('Total bookings: ${allBookings.length}');
      debugPrint('Member status: $isMember');
      if (allBookings.isNotEmpty) {
        debugPrint('First booking type: ${allBookings.first.type}');
      }
    } catch (e) {
      debugPrint('Error fetching booking data: $e');
      if (mounted) {
        setState(() => isLoading = false);

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data. Coba lagi.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  (List<dynamic>, List<dynamic>) _separateBookings(
    List<dynamic> bookings,
    DateTime today,
  ) {
    final pastBookings = <dynamic>[];
    final upcomingBookings = <dynamic>[];

    for (final booking in bookings) {
      final bookingDate = DateTime.parse(booking.date.toString());
      final isPast =
          bookingDate.isBefore(today) ||
          (bookingDate.isAtSameMomentAs(today) &&
              _isTimeInPast(booking.startTime));

      if (isPast) {
        pastBookings.add(booking);
      } else {
        upcomingBookings.add(booking);
      }
    }

    return (pastBookings, upcomingBookings);
  }

  List<Riwayat> _convertToRiwayat(List<BookingGroup> groups) {
    final riwayats =
        groups
            .map(
              (group) => Riwayat(
                tanggal: group.date,
                keterangan: "Lapangan ${group.courtId}",
                waktu: group.combinedTimeRange,
                type:
                    isMember
                        ? 'Member'
                        : 'Non Member', // Menggunakan isMember yang sudah di-set
              ),
            )
            .toList();

    // Sort by date (newest first) then by time
    riwayats.sort((a, b) {
      final dateCompare = b.tanggal.compareTo(a.tanggal);
      return dateCompare != 0 ? dateCompare : a.waktu.compareTo(b.waktu);
    });

    return riwayats;
  }

  List<Terjadwal> _convertToTerjadwal(List<BookingGroup> groups) {
    final terjadwals =
        groups
            .map(
              (group) => Terjadwal(
                tanggal: group.date,
                jam: group.combinedTimeRange,
                lapangan: "Lapangan ${group.courtId}",
                type:
                    isMember
                        ? 'Member'
                        : 'Non Member', // Menggunakan isMember yang sudah di-set
              ),
            )
            .toList();

    // Sort by date (earliest first) then by time
    terjadwals.sort((a, b) {
      final dateCompare = a.tanggal.compareTo(b.tanggal);
      return dateCompare != 0 ? dateCompare : a.jam.compareTo(b.jam);
    });

    return terjadwals;
  }

  // Booking Grouping Logic
  List<BookingGroup> _groupConsecutiveBookings(List<dynamic> bookings) {
    if (bookings.isEmpty) return [];

    final groupedBookings = <String, Map<String, List<String>>>{};

    // Group bookings by date and court
    for (final booking in bookings) {
      final date = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(booking.date.toString()));
      final courtId = booking.courtId.toString();
      final timeSlot = '${booking.startTime} - ${booking.endTime}';

      groupedBookings[date] ??= {};
      groupedBookings[date]![courtId] ??= [];
      groupedBookings[date]![courtId]!.add(timeSlot);
    }

    final result = <BookingGroup>[];

    for (final MapEntry(key: date, value: courts) in groupedBookings.entries) {
      for (final MapEntry(key: courtId, value: timeSlots) in courts.entries) {
        result.addAll(_createConsecutiveGroups(date, courtId, timeSlots));
      }
    }

    return result;
  }

  List<BookingGroup> _createConsecutiveGroups(
    String date,
    String courtId,
    List<String> timeSlots,
  ) {
    // Sort time slots
    timeSlots.sort((a, b) {
      final timeA = a.split(' - ')[0];
      final timeB = b.split(' - ')[0];
      return timeA.compareTo(timeB);
    });

    final result = <BookingGroup>[];
    var currentGroup = <String>[];
    String? lastEndTime;

    for (final timeSlot in timeSlots) {
      final parts = timeSlot.split(' - ');
      final startTime = parts[0];
      final endTime = parts[1];

      if (lastEndTime == null || lastEndTime == startTime) {
        // Consecutive or first slot
        if (currentGroup.isEmpty) {
          currentGroup.add(timeSlot);
        } else {
          // Update the end time of the group
          final groupStartTime = currentGroup.first.split(' - ')[0];
          currentGroup = ['$groupStartTime - $endTime'];
        }
        lastEndTime = endTime;
      } else {
        // Not consecutive, start new group
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

    return result;
  }

  // Booking Cancellation
  Future<void> _cancelBooking(
    String date,
    String courtId,
    String timeRange,
  ) async {
    try {
      final shouldCancel = await _showCancelConfirmation(
        date,
        courtId,
        timeRange,
      );
      if (shouldCancel != true) return;

      final timesToCancel = _parseTimeRange(timeRange);

      for (final timeSlot in timesToCancel) {
        final times = timeSlot.split(' - ');
        if (times.length != 2) continue;

        await FirebaseService().cancelBooking(
          username,
          date,
          courtId,
          times[0].trim(),
          times[1].trim(),
        );
      }

      _showSuccessMessage('Booking berhasil dibatalkan');
      await _fetchBookingData();
    } catch (e) {
      debugPrint('Error canceling booking: $e');
      _showErrorMessage('Terjadi kesalahan saat membatalkan booking');
    }
  }

  Future<bool?> _showCancelConfirmation(
    String date,
    String courtId,
    String timeRange,
  ) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
          ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Helper Methods
  List<String> _parseTimeRange(String timeRange) {
    final times = timeRange.split(' - ');
    final startTime = times[0];
    final endTime = times[1];

    final timeSlots = <String>[];
    final start = DateFormat('HH:mm').parse(startTime);
    final end = DateFormat('HH:mm').parse(endTime);

    var current = start;
    while (current.isBefore(end)) {
      final next = current.add(const Duration(minutes: 30));
      final currentStr = DateFormat('HH:mm').format(current);
      final nextStr = DateFormat('HH:mm').format(next);
      timeSlots.add('$currentStr - $nextStr');
      current = next;
    }

    return timeSlots;
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

  String _namaHari(int weekday) => daftarHari[weekday - 1];

  bool _isHariDalamRange(String hari, String mulai, String selesai) {
    final indexHari = daftarHari.indexOf(hari);
    final indexMulai = daftarHari.indexOf(mulai);
    final indexSelesai = daftarHari.indexOf(selesai);

    if (indexMulai <= indexSelesai) {
      return indexHari >= indexMulai && indexHari <= indexSelesai;
    } else {
      // Range seperti "Jumat - Senin"
      return indexHari >= indexMulai || indexHari <= indexSelesai;
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Price Calculation
  Future<double> _calculateTotalPrice({
    required String startTime,
    required String endTime,
    required DateTime selectedDate,
    required String type,
  }) async {
    try {
      final hargaList = await FirebaseService().getHarga();
      final hariBooking = _namaHari(selectedDate.weekday);

      final startMinutes = _timeToMinutes(startTime);
      final endMinutes = _timeToMinutes(endTime);

      double totalPrice = 0;

      for (int time = startMinutes; time < endMinutes; time += 30) {
        final jam = time ~/ 60;

        final hargaMatch =
            hargaList
                .where(
                  (harga) =>
                      harga.type == type &&
                      _isHariDalamRange(
                        hariBooking,
                        harga.hariMulai,
                        harga.hariSelesai,
                      ) &&
                      jam >= harga.startTime &&
                      jam < harga.endTime,
                )
                .firstOrNull;

        if (hargaMatch != null) {
          totalPrice += hargaMatch.harga / 2;
        } else {
          debugPrint(
            'No matching price found for: $type, $hariBooking, $jam:${time % 60}',
          );
        }
      }

      return totalPrice;
    } catch (e) {
      debugPrint('Error calculating price: $e');
      return 0;
    }
  }

  // UI Components
  Widget _buildDetailDialog(
    String date,
    String lapangan,
    String waktu,
    String type,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Detail Booking",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text("Tanggal: $date"),
            const SizedBox(height: 8),
            Text("Lapangan: ${lapangan.split('Lapangan ')[1]}"),
            const SizedBox(height: 8),
            Text("Waktu: $waktu"),
            const SizedBox(height: 8),
            Text(
              "Status: $type",
              style: TextStyle(
                color: type == 'Member' ? Colors.blue : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<double>(
              future: _calculateTotalPrice(
                startTime: waktu.split(' - ')[0],
                endTime: waktu.split(' - ')[1],
                selectedDate: DateFormat('yyyy-MM-dd').parse(date),
                type: type,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Menghitung harga...');
                } else if (snapshot.hasError) {
                  return Text('Gagal menghitung harga: ${snapshot.error}');
                } else {
                  final price = snapshot.data ?? 0;
                  return Text(
                    'Total Harga: Rp ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _fetchBookingData,
      child:
          riwayats.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("Tidak ada riwayat pemesanan")),
                ],
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: riwayats.length,
                itemBuilder: (context, index) {
                  final riwayat = riwayats[index];
                  return GestureDetector(
                    onTap:
                        () => _showDetailDialog(
                          riwayat.tanggal,
                          riwayat.keterangan,
                          riwayat.waktu,
                          riwayat.type,
                        ),
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(riwayat.keterangan),
                            Text(
                              riwayat.type,
                              style: TextStyle(
                                color:
                                    riwayat.type == 'Member'
                                        ? Colors.blue
                                        : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildScheduledTab() {
    return RefreshIndicator(
      onRefresh: _fetchBookingData,
      child:
          terjadwals.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("Tidak ada jadwal pemesanan mendatang")),
                ],
              )
              : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: terjadwals.length,
                itemBuilder: (context, index) {
                  final booking = terjadwals[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GestureDetector(
                      onTap:
                          () => _showDetailDialog(
                            booking.tanggal,
                            booking.lapangan,
                            booking.jam,
                            booking.type,
                          ),
                      child: Dismissible(
                        key: ValueKey(
                          '${booking.tanggal}_${booking.lapangan}_${booking.jam}',
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          final courtId = booking.lapangan.replaceAll(
                            'Lapangan ',
                            '',
                          );
                          await _cancelBooking(
                            booking.tanggal,
                            courtId,
                            booking.jam,
                          );
                          return false;
                        },
                        background: _buildDismissBackground(),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booking.lapangan),
                                Text(
                                  booking.type,
                                  style: TextStyle(
                                    color:
                                        booking.type == 'Member'
                                            ? Colors.blue
                                            : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.red,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.cancel, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Batal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(
    String date,
    String lapangan,
    String waktu,
    String type,
  ) {
    showDialog(
      context: context,
      builder: (context) => _buildDetailDialog(date, lapangan, waktu, type),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
                  children: [_buildHistoryTab(), _buildScheduledTab()],
                ),
      ),
    );
  }
}
