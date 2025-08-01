import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/function/price/price.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/function/calender/legend_item.dart';
import 'package:flutter_application_1/services/booking/member/booking_member.dart';
import 'package:flutter_application_1/services/time_slot/firebase_get_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';
import 'package:flutter_application_1/services/booking/nonmember/booking_nonmember.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});

  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

class _HalamanKalenderState extends State<HalamanKalender> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;

  // Improved data structure with type safety
  Map<String, Map<String, dynamic>> bookingData = {};
  List<String> courtIds = [];
  Set<String> processingCells = {};

  // Cache for user data
  String? _cachedUsername;
  String? _cacheRole;
  int? _memberTotalDays;
  int? _memberTotalBooking;
  int? _memberCurrentTotalBooking;
  int? _memberBookingLength;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Consolidated initialization method
  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadOrCreateSlots(selectedDate);
  }

  // Cache user data to avoid repeated SharedPreferences calls
  Future<void> _loadUserData() async {
    if (_cachedUsername == null) {
      final prefs = await SharedPreferences.getInstance();
      _cachedUsername = prefs.getString('username') ?? '';
      bool isMember = prefs.getBool('isMemberUI') ?? false;
      _cacheRole = isMember ? 'member' : 'nonMember';
      _memberTotalDays = isMember ? prefs.getInt('memberTotalDays') : null;
      _memberTotalBooking = prefs.getInt('memberTotalBooking');
      _memberCurrentTotalBooking = prefs.getInt('memberCurrentTotalBooking');
      _memberBookingLength = prefs.getInt('memberBookingLength');

      setState(() {
        _cachedUsername = _cachedUsername;
        _cacheRole = _cacheRole;
        _memberTotalDays = _memberTotalDays;
        _memberBookingLength = _memberBookingLength;
        _memberCurrentTotalBooking = _memberCurrentTotalBooking;
        _memberTotalBooking = _memberTotalBooking;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              } catch (e) {
                print('DatePicker error: $e');
              }
            },
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildStatusLegend(),
          _buildCalendarContent(),
        ],
      ),
    );
  }

  // Extracted widget methods for better organization
  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            formatLongDate(selectedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDateNavigationButton(
                icon: Icons.arrow_back,
                onPressed:
                    () => _changeDate(
                      selectedDate.subtract(const Duration(days: 1)),
                    ),
                isPrimary: false,
              ),
              const SizedBox(width: 16),
              _buildDateNavigationButton(
                text: 'Hari Ini',
                onPressed: () => _changeDate(DateTime.now()),
                isPrimary: true,
              ),
              const SizedBox(width: 16),
              _buildDateNavigationButton(
                icon: Icons.arrow_forward,
                onPressed:
                    () =>
                        _changeDate(selectedDate.add(const Duration(days: 1))),
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigationButton({
    IconData? icon,
    String? text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? primaryColor : Colors.white,
        foregroundColor: isPrimary ? Colors.white : primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: icon != null ? Icon(icon) : Text(text!),
    );
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

  Widget _buildCalendarContent() {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text('Memuat data booking...'),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => _loadOrCreateSlots(selectedDate),
        color: primaryColor,
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildCalendarTable(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarTable() {
    final sortedCourtIds = _getSortedCourtIds();

    return Column(
      children: [
        _buildTableHeader(sortedCourtIds),
        ...bookingData.entries.map(
          (entry) => _buildTableRow(entry.key, entry.value, sortedCourtIds),
        ),
      ],
    );
  }

  Widget _buildTableHeader(List<String> sortedCourtIds) {
    return Container(
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Jam', width: 110),
          ...sortedCourtIds.map(
            (id) => _buildHeaderCell('Lapangan $id', width: 110),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String time,
    Map<String, dynamic> courts,
    List<String> sortedCourtIds,
  ) {
    return Row(
      children: [
        _buildTimeCell(time, width: 110),
        ...sortedCourtIds.map((id) {
          final courtData =
              courts[id] ??
              TimeSlotModel(
                isAvailable: true,
                isClosed: false,
                isHoliday: false,
                type: '',
                username: '',
              );
          return _buildCourtCell(
            time,
            id,
            courtData.username,
            courtData.type,
            courtData.isAvailable,
            courtData.isClosed,
            courtData.isHoliday,
          );
        }),
      ],
    );
  }

  List<String> _getSortedCourtIds() {
    return courtIds.toList()..sort((a, b) => a.compareTo(b));
  }

  void _changeDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadOrCreateSlots(date);
  }

  Future<void> _loadCourts() async {
    try {
      final courtsSnapshot =
          await FirebaseFirestore.instance.collection('lapangan').get();
      courtIds =
          courtsSnapshot.docs.map((doc) => doc['nomor'].toString()).toList();
    } catch (e) {
      debugPrint('Error loading courts: $e');
      courtIds = [];
    }
  }

  Future<void> _buildBookingData(List<TimeSlotModel> slots) async {
    setState(() => isLoading = true);

    try {
      await _loadCourts();

      Map<String, Map<String, TimeSlotModel>> tempData = {};

      for (final slot in slots) {
        final timeRange = '${slot.startTime} - ${slot.endTime}';

        tempData.putIfAbsent(
          timeRange,
          () => {
            for (var courtId in courtIds)
              courtId: TimeSlotModel(isAvailable: true, isClosed: false),
          },
        );

        tempData[timeRange]![slot.courtId] = TimeSlotModel(
          isAvailable: slot.isAvailable,
          isClosed: slot.isClosed,
          isHoliday: slot.isHoliday,
          username: slot.username,
          type: slot.type,
        );
      }

      debugPrint(tempData.toString());

      setState(() {
        bookingData = tempData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal memuat data booking');
    }
  }

  Future<void> _loadOrCreateSlots(DateTime selectedDate) async {
    setState(() => isLoading = true);

    try {
      final slots = await FirebaseGetTimeSlot().getTimeSlot(selectedDate);

      if (slots.isEmpty) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);
        final newSlots = await FirebaseGetTimeSlot().getTimeSlot(selectedDate);
        await _buildBookingData(newSlots);
      } else {
        await _buildBookingData(slots);
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal memuat data slot: $e');
    }
  }

  Future<void> _performBooking(
    String startTime,
    String endTime,
    String court,
    DateTime selectedDate,
    String username,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      final startTotalMinutes = timeToMinutes(startTime);
      final endTotalMinutes = timeToMinutes(endTime);
      double totalHours = (endTotalMinutes - startTotalMinutes) / 60.0;

      // Book each 30-minute slot
      for (
        int minutes = startTotalMinutes;
        minutes < endTotalMinutes;
        minutes += 30
      ) {
        final formattedTime = minutesToFormattedTime(minutes);

        if (_cacheRole != 'member') {
          await BookingNonMember().bookSlotForNonMember(
            court,
            dateStr,
            formattedTime,
            username,
            totalHours,
          );
        } else {
          await BookingMember().bookSlotForMember(
            court,
            dateStr,
            formattedTime,
            username,
          );
        }
      }

      if (_cacheRole != 'member') {
        await BookingNonMember().addTotalBooking(username);
        await BookingNonMember().addBookingDates(username, [dateStr]);
      } else {
        await BookingMember().addTotalBooking(username);
        await BookingMember().addBookingDates(username, [dateStr]);
      }
    } catch (e) {
      debugPrint('Error performing booking: $e');
      rethrow;
    }
  }

  Widget _buildConfirmationDialog(
    String startTime,
    String endTime,
    String court,
    DateTime selectedDate,
    String username,
  ) {
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text(
            'Konfirmasi Booking',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah anda yakin ingin booking?',
                style: TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 5),

              Text(formatLongDate(selectedDate)),
              Text('Jam $startTime - $endTime'),

              const SizedBox(height: 5),

              FutureBuilder<double>(
                future: totalPrice(
                  startTime: startTime,
                  endTime: endTime,
                  selectedDate: selectedDate,
                  type: _cacheRole!,
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
              const SizedBox(height: 10),
              const Text(
                'Catatan: Booking tidak dikenakan DP, harap datang sesuai jadwal yang dipilih',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (isLoading) ...[
                const SizedBox(height: 20),
                const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Sedang memproses booking...'),
                  ],
                ),
              ],
            ],
          ),
          actions:
              isLoading
                  ? []
                  : [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() => isLoading = true);

                        try {
                          await _performBooking(
                            startTime,
                            endTime,
                            court,
                            selectedDate,
                            username,
                          );
                          await _updateSlot(selectedDate);

                          if (!context.mounted) return;
                          showSuccessSnackBar(
                            context,
                            'Berhasil booking Lapangan $court pada hari ${formatDate(selectedDate)} pukul $startTime - $endTime',
                          );

                          Navigator.pop(context);
                        } catch (e) {
                          setState(() => isLoading = false);
                          showErrorSnackBar(
                            context,
                            'Gagal melakukan booking: $e',
                          );
                          debugPrint('Error booking: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: const Text(
                        'Konfirmasi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
        );
      },
    );
  }

  Future<void> _updateSlot(DateTime selectedDate) async {
    try {
      final updatedSlots = await FirebaseGetTimeSlot().getTimeSlot(
        selectedDate,
      );
      await _buildBookingData(updatedSlots);
    } catch (e) {
      debugPrint('Error updating slot: $e');
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal memperbarui data');
    }
  }

  bool _isTimePast(String timeSlot, DateTime date) {
    try {
      final now = DateTime.now();
      final endTime = timeSlot.split(' - ')[1];
      final timeParts = endTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final slotDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      return slotDateTime.isBefore(now);
    } catch (e) {
      debugPrint("Error parsing timeSlot: $e");
      return false;
    }
  }

  String _getCellKey(String time, String court) => '${time}_$court';

  Future<void> _showBookingDialog(
    String time,
    String court,
    bool isAvailable,
    bool isClosed,
    DateTime selectedDate,
  ) async {
    final cellKey = _getCellKey(time, court);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _memberTotalBooking = prefs.getInt('memberTotalBooking');
    _memberCurrentTotalBooking = prefs.getInt('memberCurrentTotalBooking');
    _memberBookingLength = prefs.getInt('memberBookingLength');

    setState(() {
      _memberBookingLength = _memberBookingLength;
      _memberCurrentTotalBooking = _memberCurrentTotalBooking;
      _memberTotalBooking = _memberTotalBooking;
    });

    _cacheRole == 'member'
        ? (_memberCurrentTotalBooking == _memberTotalBooking
            ? showErrorSnackBar(
              context,
              'Anda sudah mencapai batas booking member',
            )
            : null)
        : (null);

    if (_cacheRole == 'member' &&
        _memberCurrentTotalBooking == _memberTotalBooking) {
      return;
    }

    if (processingCells.contains(cellKey)) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Sedang memproses, mohon tunggu...');
      return;
    }

    setState(() => processingCells.add(cellKey));

    try {
      if (isClosed) {
        showCustomSnackBar(context, 'Lapangan ditutup pada waktu ini');
        return;
      }

      await _loadUserData();
      final username = _cachedUsername ?? '';

      if (!isAvailable) {
        _showBookingInfoDialog(time, court, selectedDate, isAvailable: false);
        return;
      }

      final maxConsecutiveSlots = await _calculateMaxConsecutiveSlots(
        time,
        court,
        selectedDate,
      );

      _showBookingSelectionDialog(
        time,
        court,
        selectedDate,
        username,
        maxConsecutiveSlots,
      );
    } finally {
      setState(() => processingCells.remove(cellKey));
    }
  }

  Future<int> _calculateMaxConsecutiveSlots(
    String time,
    String court,
    DateTime selectedDate,
  ) async {
    try {
      final startTime = time.split(' - ')[0];
      final startIndex = timeSlots.indexOf(startTime);

      if (startIndex == -1) return 1;

      final currentHour = int.parse(startTime.split(':')[0]);
      final currentMinute = int.parse(startTime.split(':')[1]);
      final startTotalMinutes = currentHour * 60 + currentMinute;
      final remainingMinutes = (23 * 60) - startTotalMinutes;
      final maxPossibleSlots = remainingMinutes ~/ 30;

      final slotStatuses = await FirebaseGetTimeSlot().getSlotRangeAvailability(
        startTime: startTime,
        court: court,
        date: selectedDate,
        maxSlots: maxPossibleSlots,
      );

      int consecutiveSlots = 0;
      for (int i = 0; i < slotStatuses.length; i++) {
        final slot = slotStatuses[i];
        if (slot.isAvailable && !slot.isClosed) {
          consecutiveSlots++;
        } else {
          break;
        }
      }
      debugPrint('role: $_cacheRole');
      return consecutiveSlots;
    } catch (e) {
      debugPrint('Error calculating consecutive slots: $e');
      return 1;
    }
  }

  void _showBookingInfoDialog(
    String time,
    String court,
    DateTime selectedDate, {
    required bool isAvailable,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              isAvailable ? 'Booking Lapangan' : 'Lapangan Telah Dibooking',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${formatDate(selectedDate)}'),
                Text('Waktu: $time'),
                Text('Lapangan: $court'),
                if (!isAvailable)
                  const Text(
                    'Status: Telah dibooking',
                    style: TextStyle(color: Colors.red),
                  ),
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

  void _showBookingSelectionDialog(
    String time,
    String court,
    DateTime selectedDate,
    String username,
    int maxSlots,
  ) {
    int selectedDuration = 1; // Move it here to persist across rebuilds
    final startTime = time.split(' - ')[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final endTime = calculateEndTime(startTime, selectedDuration);

            return AlertDialog(
              title: const Text('Booking Lapangan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal: ${formatDate(selectedDate)}'),
                  Text('Waktu mulai: $startTime'),
                  Text('Lapangan: $court'),
                  const SizedBox(height: 16),
                  const Text('Durasi booking:'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<int>(
                      value: selectedDuration,
                      isExpanded: true,
                      underline: Container(),
                      onChanged: (value) {
                        setState(() {
                          selectedDuration =
                              value!; // Update the outer variable
                        });
                      },
                      items:
                          List.generate(maxSlots, (i) => i + 1).map((duration) {
                            final endTime = calculateEndTime(
                              startTime,
                              duration,
                            );
                            return DropdownMenuItem(
                              value: duration,
                              child: Text('$endTime (${duration * 30} menit)'),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Waktu selesai: $endTime',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder:
                          (context) => _buildConfirmationDialog(
                            startTime,
                            endTime,
                            court,
                            selectedDate,
                            username,
                          ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Widget builder methods
  Widget _buildHeaderCell(String text, {double width = 110}) {
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
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimeCell(String time, {double width = 110}) {
    return Container(
      width: width,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCourtCell(
    String time,
    String court,
    String username,
    String type,
    bool isAvailable,
    bool isClosed,
    bool isHoliday,
  ) {
    debugPrint(
      'username: $username, type: $type, isAvailable: $isAvailable, isClosed: $isClosed, isHoliday: $isHoliday',
    );
    final isPast = _isTimePast(time, selectedDate);
    final cellKey = _getCellKey(time, court);
    final isProcessing = processingCells.contains(cellKey);

    Color backgroundColor;
    Color textColor;
    String displayText;

    if (isClosed) {
      backgroundColor = Colors.grey;
      textColor = Colors.black;
      displayText = 'Tutup';
    } else if (isAvailable) {
      if (isHoliday) {
        backgroundColor = holidayColor;
        textColor = Colors.black;
        displayText = 'Hari Libur';
      } else {
        backgroundColor = availableColor;
        textColor = Colors.black;
        displayText = 'Tersedia';
      }
    } else {
      backgroundColor = bookedColor;
      textColor = type == 'member' ? Colors.blue : Colors.red;
      displayText = username;
    }

    debugPrint(
      '$_cacheRole, $_memberCurrentTotalBooking, $_memberTotalBooking',
    );

    // Function to handle cell tap with appropriate feedback
    void handleCellTap() {
      if (isPast) {
        showErrorSnackBar(
          context,
          'Waktu ini sudah lewat, tidak bisa dibooking',
        );
        return;
      } else if (_cacheRole == 'member' &&
          _memberCurrentTotalBooking == _memberTotalBooking) {
        showErrorSnackBar(context, 'Anda sudah mencapai batas booking member');
      }
      _showBookingDialog(time, court, isAvailable, isClosed, selectedDate);
    }

    return GestureDetector(
      onTap: isProcessing ? null : handleCellTap,
      child: Container(
        width: 110,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child:
            isProcessing
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
                : Text(
                  displayText,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
      ),
    );
  }
}
