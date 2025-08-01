import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/function/price/price.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';
import 'package:flutter_application_1/services/booking/member/cancel_member.dart';
import 'package:flutter_application_1/services/booking/nonmember/cancel_nonmember.dart';

class HalamanAktivitas extends StatefulWidget {
  const HalamanAktivitas({super.key});

  @override
  State<HalamanAktivitas> createState() => _HalamanAktivitasState();
}

class _HalamanAktivitasState extends State<HalamanAktivitas>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<TimeSlotModel> riwayats = [];
  List<TimeSlotModel> terjadwals = [];
  bool isLoading = true;
  String username = '';

  @override
  bool get wantKeepAlive => false;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _fetchBookingData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (username.isNotEmpty) {
      _fetchBookingData();
    }
  }

  Future<void> _initialize() async {
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    await _fetchBookingData();
  }

  Future<void> _fetchBookingData() async {
    if (!mounted) return;

    if (riwayats.isEmpty && terjadwals.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      // Use Future.wait for parallel processing
      final results = await Future.wait([
        FirebaseGetBooking().getBookingByUsername(username),
        FirebaseGetBooking().getCancelBookingByUsername(username),
      ]);

      final allBookings = results[0];
      final cancelBookings = results[1];

      if (!mounted) return;

      // Pre-calculate today once
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Process data in background using compute for heavy operations
      final processedData = await _processBookingData(
        allBookings,
        cancelBookings,
        today,
      );

      setState(() {
        riwayats = processedData['past'] as List<TimeSlotModel>;
        terjadwals = processedData['upcoming'] as List<TimeSlotModel>;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching booking data: $e');
      if (mounted) {
        setState(() => isLoading = false);
        showErrorSnackBar(context, 'Gagal memuat data. Coba lagi.');
      }
    }
  }

  Future<Map<String, List<TimeSlotModel>>> _processBookingData(
    List<TimeSlotModel> allBookings,
    List<TimeSlotModel> cancelBookings,
    DateTime today,
  ) async {
    // Use Map for faster lookups instead of List operations
    final Map<String, List<TimeSlotModel>> bookingsByDate = {};
    final Map<String, List<TimeSlotModel>> cancelByDate = {};

    // Group bookings by date first (faster than checking each one)
    for (final booking in allBookings) {
      bookingsByDate[booking.date] ??= [];
      print('Processing booking for date: ${booking.date}');
      bookingsByDate[booking.date]!.add(booking);
    }

    for (final booking in cancelBookings) {
      cancelByDate[booking.date] ??= [];
      cancelByDate[booking.date]!.add(booking);
    }

    final pastBookings = <TimeSlotModel>[];
    final upcomingBookings = <TimeSlotModel>[];

    // Process each date group
    for (final entry in bookingsByDate.entries) {
      final dateStr = entry.key;
      final bookings = entry.value;
      // final bookingDate = DateTime.parse(dateStr);
      print('Processing bookings for date: $dateStr');
      final bookingDate = DateFormat('yyyy-MM-dd').parse(dateStr);

      if (bookingDate.isBefore(today)) {
        // All bookings on this date are past
        pastBookings.addAll(bookings);
      } else if (bookingDate.isAfter(today)) {
        // All bookings on this date are upcoming
        upcomingBookings.addAll(bookings);
      } else {
        // Today - need to check individual times
        for (final booking in bookings) {
          if (_isTimeInPast(booking.startTime)) {
            pastBookings.add(booking);
          } else {
            upcomingBookings.add(booking);
          }
        }
      }
    }

    // Add all cancel bookings to past (they're already processed)
    pastBookings.addAll(cancelBookings);

    // Group consecutive bookings efficiently
    final pastGroups = _groupConsecutiveBookings(pastBookings);
    final upcomingGroups = _groupConsecutiveBookings(upcomingBookings);

    return {'past': pastGroups, 'upcoming': upcomingGroups};
  }

  List<TimeSlotModel> _groupConsecutiveBookings(
    List<TimeSlotModel> bookings,
  ) {
    if (bookings.isEmpty) return [];

    // Use Map with compound key for faster grouping
    final Map<String, List<TimeSlotModel>> groups = {};

    for (final booking in bookings) {
      final key = '${booking.date}_${booking.courtId}';
      groups[key] ??= [];
      groups[key]!.add(booking);
    }

    final result = <TimeSlotModel>[];

    for (final timeSlots in groups.values) {
      // Sort once by start time
      timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Create consecutive groups more efficiently
      final consecutiveGroups = _createConsecutiveGroups(timeSlots);
      result.addAll(consecutiveGroups);
    }

    // Sort final result by date and time
    result.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.startTime.compareTo(b.startTime);
    });

    return result;
  }

  List<TimeSlotModel> _createConsecutiveGroups(
    List<TimeSlotModel> timeSlots,
  ) {
    if (timeSlots.isEmpty) return [];

    final result = <TimeSlotModel>[];
    final currentGroup = <TimeSlotModel>[timeSlots.first];

    for (int i = 1; i < timeSlots.length; i++) {
      final current = timeSlots[i];
      final previous = currentGroup.last;

      // Check if times are consecutive (exactly 30 minutes apart)
      if (_areTimesConsecutive(previous.endTime, current.startTime)) {
        currentGroup.add(current);
      } else {
        // Create grouped time slot and start new group
        result.add(_createGroupedTimeSlot(currentGroup));
        currentGroup.clear();
        currentGroup.add(current);
      }
    }

    // Add the last group
    if (currentGroup.isNotEmpty) {
      result.add(_createGroupedTimeSlot(currentGroup));
    }

    return result;
  }

  bool _areTimesConsecutive(String endTime, String startTime) {
    // Simple string comparison for exact matches
    return endTime == startTime;
  }

  TimeSlotModel _createGroupedTimeSlot(List<TimeSlotModel> group) {
    final first = group.first;
    final last = group.last;

    return TimeSlotModel(
      slotId: first.slotId,
      courtId: first.courtId,
      date: first.date,
      startTime: first.startTime,
      endTime: last.endTime,
      type: first.type,
      username: first.username,
      isAvailable: first.isAvailable,
      isClosed: first.isClosed,
      isHoliday: first.isHoliday,
      cancel: first.cancel,
    );
  }

  Future<void> _cancelBooking(TimeSlotModel booking) async {
    try {
      final shouldCancel = await _showCancelConfirmation(booking);
      if (shouldCancel != true) return;

      // Parse time range untuk mendapatkan individual time slots
      final timesToCancel = _parseTimeRange(
        '${booking.startTime} - ${booking.endTime}',
      );

      if (booking.type == 'member') {
        for (final timeSlot in timesToCancel) {
          final times = timeSlot.split(' - ');
          if (times.length != 2) continue;

          await CancelMember().cancelBooking(
            username,
            booking.date,
            booking.courtId,
            times[0].trim(),
            times[1].trim(),
          );
          await CancelMember().updateUserCancel(username, booking.date);
        }
      } else {
        for (final timeSlot in timesToCancel) {
          final times = timeSlot.split(' - ');
          if (times.length != 2) continue;

          await CancelNonMember().cancelBooking(
            username,
            booking.date,
            booking.courtId,
            times[0].trim(),
            times[1].trim(),
          );
          await CancelNonMember().updateUserCancel(username, booking.date);
        }
      }

      if (!mounted) return;
      showSuccessSnackBar(context, 'Booking berhasil dibatalkan');
      await _fetchBookingData();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Terjadi kesalahan saat membatalkan booking');
    }
  }

  Future<bool?> _showCancelConfirmation(TimeSlotModel booking) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Pembatalan'),
            content: Text(
              'Apakah Anda yakin ingin membatalkan booking?\n\n'
              'Lapangan: ${booking.courtId}\n'
              'Tipe: ${booking.type == 'member' ? 'Member' : 'Non Member'}\n'
              'Waktu: ${booking.startTime} - ${booking.endTime}\n'
              'Tanggal: ${formatLongDate(DateTime.parse(booking.date))}',
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

  String _getStatusColor(String type) {
    return type.toLowerCase() == 'member' ? 'Member' : 'Non Member';
  }

  Color _getTypeColor(String type) {
    return type.toLowerCase() == 'member' ? Colors.blue : Colors.orange;
  }

  Widget _buildDetailDialog(TimeSlotModel booking) {
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
            Text("Lapangan: ${booking.courtId}"),
            const SizedBox(height: 8),
            Text("Tanggal: ${formatStrToLongDate(booking.date)}"),
            const SizedBox(height: 8),
            Text("Waktu: ${booking.startTime} - ${booking.endTime}"),
            const SizedBox(height: 8),
            Text(
              "Status: ${_getStatusColor(booking.type)}",
              style: TextStyle(
                color: _getTypeColor(booking.type),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<double>(
              future: totalPrice(
                startTime: booking.startTime,
                endTime: booking.endTime,
                selectedDate: DateTime.parse(booking.date),
                type:
                    booking.type.toLowerCase() == 'member'
                        ? 'member'
                        : 'nonMember',
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
                  final booking = riwayats[index];
                  print(booking.cancel);
                  return booking.cancel.isEmpty ?
                  GestureDetector(
                    onTap: () => _showDetailDialog(booking),
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
                              booking.date,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${booking.startTime} - ${booking.endTime}",
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Lapangan ${booking.courtId}"),
                            Text(
                              _getStatusColor(booking.type),
                              style: TextStyle(
                                color: _getTypeColor(booking.type),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ):
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                      ),
                      title: Row(
                        children: [
                          Text(
                            booking.date,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "${booking.startTime} - ${booking.endTime}",
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Lapangan ${booking.courtId}"),
                          Text(
                            _getStatusColor(booking.type),
                            style: TextStyle(
                              color: _getTypeColor(booking.type),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                          onTap: () => _showDetailDialog(booking),
                          child: Dismissible(
                            key: ValueKey(
                              '${booking.date}_${booking.courtId}_${booking.startTime}_${booking.endTime}',
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              await _cancelBooking(booking);
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
                                      booking.date,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${booking.startTime} - ${booking.endTime}",
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Lapangan ${booking.courtId}"),
                                    Text(
                                      _getStatusColor(booking.type),
                                      style: TextStyle(
                                        color: _getTypeColor(booking.type),
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

  void _showDetailDialog(TimeSlotModel booking) {
    showDialog(
      context: context,
      builder: (context) => _buildDetailDialog(booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
