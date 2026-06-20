import 'package:flutter_application_1/services/user/firebase_get_user.dart';
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
  final int tabIndex;
  const HalamanAktivitas({super.key, this.tabIndex = 0});

  @override
  State<HalamanAktivitas> createState() => _HalamanAktivitasState();
}

class _HalamanAktivitasState extends State<HalamanAktivitas>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin,
        SingleTickerProviderStateMixin {
  List<TimeSlotModel> riwayats = [];
  List<TimeSlotModel> terjadwals = [];
  List<TimeSlotModel> cancels = [];
  bool isLoading = true;
  String username = '';

  late TabController _tabController;

  // Add loading states for individual bookings
  Set<String> cancellingBookings = {};

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.tabIndex,
    );
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

      List<TimeSlotModel> allBookings = results[0];

      List<TimeSlotModel> cancelBookings = results[1];

      if (!mounted) return;

      // Pre-calculate today once
      final now = DateTime.now();
      final today = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      );

      // Process data in background using compute for heavy operations
      final processedData = await _processBookingData(allBookings, today);

      setState(() {
        riwayats = processedData['past'] as List<TimeSlotModel>;
        terjadwals = processedData['upcoming'] as List<TimeSlotModel>;
        cancels = cancelBookings;
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
    DateTime today,
  ) async {
    List<TimeSlotModel> pastBookings = [];
    List<TimeSlotModel> upcomingBookings = [];

    for (final entry in allBookings) {
      final dateStr = entry.date;
      final startTimeStr = entry.startTime;
      final endTimeStr = entry.endTime;

      // Parse the booking date (only date part)
      final bookingDateOnly = DateFormat('yyyy-MM-dd').parse(dateStr);

      // Parse start and end times
      final startTime = DateFormat('HH:mm').parse(startTimeStr);
      final endTime = DateFormat('HH:mm').parse(endTimeStr);

      // Create complete DateTime objects for start and end
      final bookingStartDateTime = DateTime(
        bookingDateOnly.year,
        bookingDateOnly.month,
        bookingDateOnly.day,
        startTime.hour,
        startTime.minute,
      );

      final bookingEndDateTime = DateTime(
        bookingDateOnly.year,
        bookingDateOnly.month,
        bookingDateOnly.day,
        endTime.hour,
        endTime.minute,
      );

      if (bookingEndDateTime.isBefore(today)) {
        // Booking ended before today - past booking
        pastBookings.add(entry);
      } else if (bookingDateOnly.isAfter(today)) {
        // Booking date is after today - upcoming booking
        upcomingBookings.add(entry);
      } else {
        // Booking is today - check if it has already ended
        if (bookingEndDateTime.isBefore(DateTime.now())) {
          pastBookings.add(entry);
        } else {
          upcomingBookings.add(entry);
        }
      }
    }

    return {'past': pastBookings, 'upcoming': upcomingBookings};
  }

  Future<List<TimeSlotModel>> _groupConsecutiveBookings(
    List<TimeSlotModel> bookings,
  ) async {
    if (bookings.isEmpty) return [];

    final Map<String, List<TimeSlotModel>> groups = {};

    for (final booking in bookings) {
      final key = '${booking.date}_${booking.courtId}_${booking.userId}';
      print('key: $key');
      groups[key] ??= [];
      groups[key]!.add(booking);
    }

    print('groups keys: ${groups.keys}');
    print('groups values: ${groups.values}');

    final result = <TimeSlotModel>[];

    for (final timeSlots in groups.values) {
      List<TimeSlotModel> userBookings =
          timeSlots
              .where(
                (slot) =>
                    ((slot.userId.isNotEmpty && !slot.isAvailable) ||
                        slot.cancel.isNotEmpty),
              )
              .toList();

      if (userBookings.isEmpty) continue;

      userBookings.sort((a, b) => a.startTime.compareTo(b.startTime));
      userBookings = await _createConsecutiveGroups(userBookings);

      result.addAll(userBookings);
    }

    // Sort final result by date and time
    result.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.startTime.compareTo(b.startTime);
    });

    return result;
  }

  Future<List<TimeSlotModel>> _createConsecutiveGroups(
    List<TimeSlotModel> timeSlots,
  ) async {
    if (timeSlots.isEmpty) return [];

    final result = <TimeSlotModel>[];
    final currentGroup = <TimeSlotModel>[timeSlots.first];

    for (int i = 1; i < timeSlots.length; i++) {
      final current = timeSlots[i];
      final previous = currentGroup.last;

      if (_areTimesConsecutive(previous.endTime, current.startTime) &&
          previous.userId == current.userId &&
          previous.type == current.type &&
          previous.courtId == current.courtId) {
        currentGroup.add(current);
      } else {
        if (currentGroup.isNotEmpty) {
          result.add(await _createGroupedTimeSlot(currentGroup));
        }
        currentGroup.clear();
        currentGroup.add(current);
      }
    }

    // Add the last group
    if (currentGroup.isNotEmpty) {
      result.add(await _createGroupedTimeSlot(currentGroup));
    }

    return result;
  }

  bool _areTimesConsecutive(String endTime, String startTime) {
    // PERBAIKAN: Implementasi yang lebih robust untuk check consecutive times
    try {
      final endTimeParsed = DateFormat('HH:mm').parse(endTime);
      final startTimeParsed = DateFormat('HH:mm').parse(startTime);

      // Check if end time of previous slot equals start time of current slot
      return endTimeParsed.isAtSameMomentAs(startTimeParsed);
    } catch (e) {
      // Fallback to string comparison
      return endTime == startTime;
    }
  }

  Future<TimeSlotModel> _createGroupedTimeSlot(
    List<TimeSlotModel> group,
  ) async {
    final first = group.first;
    final last = group.last;
    final username = await FirebaseGetUser().getUserDataById(
      first.userId,
      'username',
    );

    return TimeSlotModel(
      slotId: first.slotId,
      courtId: first.courtId,
      date: first.date,
      startTime: first.startTime,
      endTime: last.endTime,
      type: first.type,
      userId: first.userId,
      username: username,
      isAvailable: first.isAvailable,
      isClosed: first.isClosed,
      isHoliday: first.isHoliday,
      cancel: first.cancel,
    );
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
            Text("Tanggal: ${booking.date}"),
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
    final combined = [
      ...riwayats.map((b) => (booking: b, isCancelled: false)),
      ...cancels.map((b) => (booking: b, isCancelled: true)),
    ]..sort((a, b) => b.booking.date.compareTo(a.booking.date));
    return RefreshIndicator(
      onRefresh: _fetchBookingData,
      child:
          combined.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("Tidak ada riwayat pemesanan")),
                ],
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: combined.length,
                itemBuilder: (context, index) {
                  final item = combined[index];
                  final booking = item.booking;
                  return !item.isCancelled
                      ? GestureDetector(
                        onTap: () => _showDetailDialog(booking),
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatLongDate(
                                      DateTime.parse(booking.date),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${booking.startTime} - ${booking.endTime}",
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.sports_tennis,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text("Lapangan ${booking.courtId}"),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(
                                          booking.type,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusColor(booking.type),
                                        style: TextStyle(
                                          color: _getTypeColor(booking.type),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      : Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.cancel, color: Colors.red),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatLongDate(DateTime.parse(booking.date)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${booking.startTime} - ${booking.endTime}",
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sports_tennis,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text("Lapangan ${booking.courtId}"),
                              ],
                            ),
                          ),
                        ),
                      );
                },
              ),
    );
  }

  // Enhanced scheduled tab with better loading UI
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
              : Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: terjadwals.length,
                    itemBuilder: (context, index) {
                      final booking = terjadwals[index];
                      final bookingKey =
                          '${booking.date}_${booking.courtId}_${booking.startTime}_${booking.endTime}';
                      final isCancelling = cancellingBookings.contains(
                        bookingKey,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onTap: () => _showDetailDialog(booking),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Card(
                              elevation: isCancelling ? 1 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: _buildLeadingWidget(isCancelling),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              formatLongDate(
                                                DateTime.parse(booking.date),
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${booking.startTime} - ${booking.endTime}",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.sports_tennis,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text("Lapangan ${booking.courtId}"),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getTypeColor(
                                              booking.type,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusColor(booking.type),
                                            style: TextStyle(
                                              color: _getTypeColor(
                                                booking.type,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
    );
  }

  Widget _buildLeadingWidget(bool isCancelling) {
    if (isCancelling) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Icon(Icons.schedule, color: Colors.blue, size: 24),
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
          bottom: TabBar(
            controller: _tabController,
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
                  controller: _tabController,
                  children: [_buildHistoryTab(), _buildScheduledTab()],
                ),
      ),
    );
  }
}
