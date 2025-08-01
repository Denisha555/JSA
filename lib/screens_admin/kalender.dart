import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/function/price/price.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/function/calender/legend_item.dart';
import 'package:flutter_application_1/services/court/firebase_get_court.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/booking/member/cancel_member.dart';
import 'package:flutter_application_1/services/booking/member/booking_member.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_get_time_slot.dart';
import 'package:flutter_application_1/services/booking/nonmember/cancel_nonmember.dart';
import 'package:flutter_application_1/services/booking/nonmember/booking_nonmember.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});

  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

class _HalamanKalenderState extends State<HalamanKalender> {
  // Tanggal sekarang untuk header kalender
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Set<String> processingCells = {};
  Set<String> loadingCells = {}; // Track which cells are loading
  bool isBookingInProgress = false; // Global booking state

  List<TimeSlotModel> timeSlot = [];
  List<String> courtIds = [];
  List<String> timeRanges = [];

  void _changeDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadOrCreateSlots(date);
  }

  void _safeNavigatorPop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext dialogContext) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Expanded(child: Text(message)),
                ],
              ),
            ),
          ),
    );
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

      return consecutiveSlots;
    } catch (e) {
      debugPrint('Error calculating consecutive slots: $e');
      return 1;
    }
  }

  // Show dialog to add a new booking
  Future<void> _showAddBookingDialog(String time, String court) async {
    // Cek jika sudah ada proses booking yang berjalan
    if (isBookingInProgress) {
      showCustomSnackBar(
        context,
        'Sedang memproses booking lain, mohon tunggu...',
      );
      return;
    }

    final TextEditingController usernameController = TextEditingController();
    String startTime = time.split(' - ')[0];
    int maxConsecutiveSlots = await _calculateMaxConsecutiveSlots(
      time,
      court,
      selectedDate,
    );

    // Show dialog dengan context yang proper
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        int selectedDuration = 1;
        String endTime = calculateEndTime(startTime, selectedDuration);
        final formKey = GlobalKey<FormState>();

        void updateEndTime() {
          int startHour = int.parse(startTime.split(':')[0]);
          int startMinute = int.parse(startTime.split(':')[1]);
          int totalMinutes =
              startHour * 60 + startMinute + (selectedDuration * 30);
          int endHour = totalMinutes ~/ 60;
          int endMinute = totalMinutes % 60;
          endTime =
              '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
        }

        return Form(
          key: formKey,
          child: StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  StateSetter setDialogState,
                ) => AlertDialog(
                  title: Text('Tambah Data Booking'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lapangan $court'),
                        Text('Jam Mulai: $startTime'),
                        Text('Jam Selesai: $endTime'),
                        SizedBox(height: 10),
                        Text(
                          'Durasi:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<int>(
                          value: selectedDuration,
                          isExpanded: true,
                          underline: Container(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDuration = value!;
                              updateEndTime();
                            });
                          },
                          items:
                              List.generate(
                                maxConsecutiveSlots,
                                (i) => i + 1,
                              ).map((e) {
                                int startHour = int.parse(
                                  startTime.split(':')[0],
                                );
                                int startMinute = int.parse(
                                  startTime.split(':')[1],
                                );
                                int totalMinutes =
                                    startHour * 60 + startMinute + (e * 30);

                                String formattedEndTime =
                                    minutesToFormattedTime(totalMinutes);

                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(formattedEndTime),
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 2.0,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: primaryColor,
                            ),
                            labelText: "Username",
                            labelStyle: const TextStyle(color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 20.0,
                            ),
                          ),
                          validator: (value) {
                            return value!.isEmpty
                                ? 'Silahkan masukkan username'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => _safeNavigatorPop(dialogContext),
                      child: Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          _confirmationDialog(
                            dialogContext,
                            usernameController.text.trim(),
                            startTime,
                            endTime,
                            court,
                            selectedDuration,
                          );
                        }
                      },
                      child: Text('Lanjut'),
                    ),
                  ],
                ),
          ),
        );
      },
    );
  }

  Future<void> _processBooking(
    BuildContext dialogContext,
    String username,
    String startTime,
    String endTime,
    String court,
    int duration,
  ) async {
    setState(() {
      isBookingInProgress = true;
    });

    _safeNavigatorPop(dialogContext); // Tutup dialog input

    if (!mounted) return;
    _showLoadingDialog(context, 'Processing booking...');

    try {
      bool userExists = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );

      if (!userExists) {
        if (!mounted) return;
        _safeNavigatorPop(context); // Tutup loading
        showErrorSnackBar(
          context,
          'Username tidak ditemukan, silahkan lakukan pendaftaran terlebih dahulu',
        );
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final startTotalMinutes = timeToMinutes(startTime);
      final endTotalMinutes = timeToMinutes(endTime);
      double totalHours = (endTotalMinutes - startTotalMinutes) / 60.0;

      List<String> bookedSlots = [];

      if (await FirebaseCheckUser().checkUserType(username) != 'member') {
        for (
          int minutes = startTotalMinutes;
          minutes < endTotalMinutes;
          minutes += 30
        ) {
          final formattedTime = minutesToFormattedTime(minutes);

          await BookingNonMember().bookSlotForNonMember(
            court,
            dateStr,
            formattedTime,
            username,
            minutes == startTotalMinutes ? totalHours : 0,
          );

          bookedSlots.add(formattedTime);
        }

        await BookingNonMember().addTotalBooking(username);
      } else {
        final bookingDates = await FirebaseGetUser().getUserData(
          username,
          'memberTotalBooking',
        );
        final currentBookingDates = await FirebaseGetUser().getUserData(
          username,
          'memberCurrentTotalBooking',
        );
        final bookingLength = await FirebaseGetUser().getUserData(
          username,
          'memberBookingLength',
        );

        if (currentBookingDates.length >= bookingDates.length) {
          // Jika melebihi jumlah hari
          for (
            int minutes = startTotalMinutes;
            minutes < endTotalMinutes;
            minutes += 30
          ) {
            final formattedTime = minutesToFormattedTime(minutes);
            await BookingNonMember().bookSlotForNonMember(
              court,
              dateStr,
              formattedTime,
              username,
              minutes == startTotalMinutes ? totalHours : 0,
            );
            bookedSlots.add(formattedTime);
          }
        } else {
          // Hitung jumlah slot
          int length = ((endTotalMinutes - startTotalMinutes) ~/ 30);
          if (length > bookingLength) {
            if (!mounted) return;
            _safeNavigatorPop(context);
            showErrorSnackBar(
              context,
              'Anda hanya bisa booking maksimal $bookingLength slot',
            );
            return;
          }

          for (
            int minutes = startTotalMinutes;
            minutes < endTotalMinutes;
            minutes += 30
          ) {
            final formattedTime = minutesToFormattedTime(minutes);
            await BookingMember().bookSlotForMember(
              court,
              dateStr,
              formattedTime,
              username,
            );
            bookedSlots.add(formattedTime);
          }

          await BookingMember().addTotalBooking(username);
          await BookingMember().addBookingDates(username, dateStr);
        }
      }

      if (!mounted) return;
      _safeNavigatorPop(context); // Tutup loading
      showSuccessSnackBar(context, 'Berhasil booking untuk $username');
      await _loadOrCreateSlots(selectedDate);
    } catch (e) {
      if (!mounted) return;
      _safeNavigatorPop(context); // Tutup loading jika error
      showErrorSnackBar(context, 'Error saat membuat booking: $e');
    } finally {
      if (mounted) {
        setState(() {
          isBookingInProgress = false;
        });
      }
    }
  }

  Future<void> _loadOrCreateSlots(DateTime selectedDate) async {
    if (mounted) {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = '';
      });
    }

    try {
      final courts =
          await FirebaseGetCourt().getCourts(); // ambil semua lapangan
      final slots = await FirebaseGetTimeSlot().getTimeSlot(selectedDate);

      final expectedSlotCount =
          courts.length * ((22 - 7 + 1) * 2); // 30 menit per jam

      bool isComplete = slots.length >= expectedSlotCount;

      if (!isComplete) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);
        final newSlots = await FirebaseGetTimeSlot().getTimeSlot(selectedDate);
        _processBookingData(newSlots);
      } else {
        _processBookingData(slots);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Error loading slots: $e');

      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _processBookingData(List<TimeSlotModel> slots) {
    try {
      timeSlot = slots;

      courtIds = slots.map((slot) => slot.courtId).toSet().toList()..sort();

      timeRanges =
          slots
              .map((slot) => '${slot.startTime} - ${slot.endTime}')
              .toSet()
              .toList()
            ..sort((a, b) {
              // Sort by start time
              String timeA = a.split(' - ')[0];
              String timeB = b.split(' - ')[0];
              return timeToMinutes(timeA).compareTo(timeToMinutes(timeB));
            });

      if (mounted) {
        setState(() {
          courtIds = courtIds;
          timeRanges = timeRanges;
          isLoading = false;
        });
      }
    } catch (e) {
      showErrorSnackBar(context, 'Error processing booking data: $e');
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  TimeSlotModel? _findSlot(String timeRange, String courtId) {
    try {
      return timeSlot.firstWhere(
        (slot) =>
            '${slot.startTime} - ${slot.endTime}' == timeRange &&
            slot.courtId == courtId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _confirmationDialog(
    BuildContext context,
    String username,
    String startTime,
    String endTime,
    String court,
    int selectedDuration,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext confirmContext)  {
        return AlertDialog(
          title: Text('Konfirmasi Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text('Customer: $username'),
                Text('Lapangan: $court'),
                Text('Jam Mulai: $startTime'),
                Text('Jam Selesai: $endTime'),
                FutureBuilder<double>(
                  future: totalPrice(
                    startTime: startTime,
                    endTime: endTime,
                    selectedDate: selectedDate,
                    type: _memberOrNonMember(username),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Menghitung harga...');
                    } else if (snapshot.hasError) {
                      return Text('Gagal menghitung harga');
                    } else {
                      final price = snapshot.data ?? 0;
                      return Text(
                        'Total Harga: Rp ${price.toStringAsFixed(0)}',
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(confirmContext).pop(false),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(confirmContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Konfirmasi'),
              ),
            ],
          );
  }
    );
    if (confirm == true && mounted) {
      _processBooking(
        context,
        username,
        startTime,
        endTime,
        court,
        selectedDuration,
      );
    }
  }

  Future<String> _memberOrNonMember(String username) async {
    final user = await FirebaseCheckUser().checkUserType(username);
    if (user != 'member') {
      return 'nonMember';
    } else {
      final bookingDates = await FirebaseGetUser().getUserData(
        username,
        'bookingDates',
      );
      final currentBookingDates = await FirebaseGetUser().getUserData(
        username,
        'currentBookingDates',
      );
      if (currentBookingDates.length >= bookingDates.length) {
        return 'nonMember';
      } else {
        return 'member';
      }
    }
  }

  // Show booking details
  Future<void> _showBookingDetails(
    String time,
    String court,
    String type,
    String username,
  ) async {
    List<String> consecutiveSlots = _findConsecutiveBookings(
      time,
      court,
      username,
    );
    String startTime = consecutiveSlots.first.split(' - ')[0];
    String endTime = consecutiveSlots.last.split(' - ')[1];

    try {
      await showDialog(
        context: context,
        builder:
            (BuildContext dialogContext) => AlertDialog(
              title: Text('Detail Booking'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: $username',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Lapangan: $court'),
                    Text('Jam Mulai: $startTime'),
                    Text('Jam Selesai: $endTime'),
                    Text(
                      'Status: ${type == "member" ? "Member" : "Non Member"}',
                    ),
                    Text('Total Durasi: ${consecutiveSlots.length * 30} menit'),
                    FutureBuilder<double>(
                      future: totalPrice(
                        startTime: startTime,
                        endTime: endTime,
                        selectedDate: selectedDate,
                        type: type,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text('Menghitung harga...');
                        } else if (snapshot.hasError) {
                          return Text('Gagal menghitung harga');
                        } else {
                          final price = snapshot.data ?? 0;
                          return Text(
                            'Total Harga: Rp ${price.toStringAsFixed(0)}',
                          );
                        }
                      },
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => _safeNavigatorPop(dialogContext),
                  child: Text('Tutup'),
                ),
                TextButton(
                  onPressed:
                      () async => await _handleCancelBooking(
                        dialogContext,
                        time,
                        court,
                      ),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('Batalkan Booking'),
                ),
              ],
            ),
      );
    } catch (e) {
      debugPrint('Error getting booking confirmation status: $e');
      // Tampilkan dialog tanpa status konfirmasi jika ada error
      if (!mounted) return;

      await showDialog(
        context: context,
        builder:
            (BuildContext dialogContext) => AlertDialog(
              title: Text('Detail Booking'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer: $username',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Lapangan: $court'),
                    Text('Jam Mulai: $startTime'),
                    Text('Jam Selesai: $endTime'),
                    Text('Total Durasi: ${consecutiveSlots.length * 30} menit'),
                    FutureBuilder<double>(
                      future: totalPrice(
                        startTime: startTime,
                        endTime: endTime,
                        selectedDate: selectedDate,
                        type: 'Non Member',
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text('Menghitung harga...');
                        } else if (snapshot.hasError) {
                          return Text('Gagal menghitung harga');
                        } else {
                          final price = snapshot.data ?? 0;
                          return Text(
                            'Total Harga: Rp ${price.toStringAsFixed(0)}',
                          );
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    if (consecutiveSlots.length > 1) ...[
                      Text(
                        'Slot yang dibooking:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      ...consecutiveSlots.map(
                        (slot) => Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('• $slot'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => _safeNavigatorPop(dialogContext),
                  child: Text('Tutup'),
                ),
                TextButton(
                  onPressed:
                      () => _handleCancelBooking(dialogContext, time, court),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(
                    consecutiveSlots.length > 1
                        ? 'Batalkan Semua'
                        : 'Batalkan Booking',
                  ),
                ),
              ],
            ),
      );
    }
  }

  List<String> _findConsecutiveBookings(
    String targetTime,
    String court,
    String username,
  ) {
    List<String> consecutiveSlots = [];

    // Find target index in sorted time ranges
    int targetIndex = timeRanges.indexWhere((slot) => slot == targetTime);
    if (targetIndex == -1) return [targetTime];

    // Check backwards for consecutive bookings
    int startIndex = targetIndex;
    for (int i = targetIndex - 1; i >= 0; i--) {
      String timeRange = timeRanges[i];
      TimeSlotModel? slot = _findSlot(timeRange, court);

      if (slot != null && !slot.isAvailable && !slot.isClosed) {
        startIndex = i;
      } else {
        break;
      }
    }

    // Check forwards for consecutive bookings
    int endIndex = targetIndex;
    for (int i = targetIndex + 1; i < timeRanges.length; i++) {
      String timeRange = timeRanges[i];
      TimeSlotModel? slot = _findSlot(timeRange, court);

      if (slot != null && !slot.isAvailable && !slot.isClosed) {
        endIndex = i;
      } else {
        break;
      }
    }

    // Collect consecutive slots
    for (int i = startIndex; i <= endIndex; i++) {
      consecutiveSlots.add(timeRanges[i]);
    }

    return consecutiveSlots;
  }

  Future<void> _handleCancelBooking(
    BuildContext dialogContext,
    String time,
    String court,
  ) async {
    _safeNavigatorPop(dialogContext);

    // Get booking info first
    final timeSlotData = timeSlot.firstWhere(
      (slot) =>
          slot.courtId == court &&
          '${slot.startTime} - ${slot.endTime}' == time &&
          slot.username.isNotEmpty,
      orElse: () => TimeSlotModel(), // fallback jika tidak ditemukan
    );

    if (timeSlotData.username.isEmpty) return;

    String username = timeSlotData.username;
    if (username.isEmpty) return;

    // Find all consecutive bookings for this user
    List<String> consecutiveSlots = _findConsecutiveBookings(
      time,
      court,
      username,
    );

    // Calculate start and end time for display
    String startTime = consecutiveSlots.first.split(' - ')[0];
    String endTime = consecutiveSlots.last.split(' - ')[1];

    // Show confirmation with booking details
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext confirmContext) => AlertDialog(
            title: Text('Konfirmasi Pembatalan Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: $username'),
                Text('Lapangan: $court'),
                Text('Jam Mulai: $startTime'),
                Text('Jam Selesai: $endTime'),
                SizedBox(height: 10),
                Text(
                  'Apakah Anda yakin ingin membatalkan booking ini?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(confirmContext).pop(false),
                child: Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.of(confirmContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Ya, Batalkan'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      setState(() {
        isBookingInProgress = true;
      });

      _showLoadingDialog(context, 'Membatalkan booking...');

      try {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

        if (timeSlotData.type == 'member') {
          for (String timeSlot in consecutiveSlots) {
            await CancelMember().cancelBooking(
              username,
              dateStr,
              court,
              timeSlot.split(' - ')[0],
              timeSlot.split(' - ')[1],
            );
          }

          await CancelMember().updateUserCancel(username, dateStr);

          if (!mounted) return;
          _safeNavigatorPop(context); // Close loading dialog
        } else {
          for (String timeSlot in consecutiveSlots) {
            await CancelNonMember().cancelBooking(
              username,
              dateStr,
              court,
              timeSlot.split(' - ')[0],
              timeSlot.split(' - ')[1],
            );
          }

          await CancelNonMember().updateUserCancel(username, dateStr);

          if (!mounted) return;
          _safeNavigatorPop(context); // Close loading dialog
        }

        if (mounted) {
          showSuccessSnackBar(
            context,
            'Berhasil membatalkan bookingan untuk $username, hari ${DateFormat('EEEE, d MMMM yyyy').format(selectedDate)}, pukul $startTime - $endTime',
          );

          // Refresh data
          await _loadOrCreateSlots(selectedDate);
        }
      } catch (e) {
        if (!mounted) return;
        _safeNavigatorPop(context); // Close loading dialog
        debugPrint('Error canceling booking: $e');

        if (!mounted) return;
        showErrorSnackBar(context, 'Error saat membatalkan booking: $e');
      } finally {
        if (mounted) {
          setState(() {
            isBookingInProgress = false;
          });
        }
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

  bool _isTimePast(String timeSlot, DateTime date) {
    try {
      debugPrint("Cek timeSlot: $timeSlot"); // debug
      final now = DateTime.now();
      final endTime = timeSlot.split(' - ')[1];
      final hour = int.parse(endTime.split(':')[0]);
      final minute = int.parse(endTime.split(':')[1]);

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

  // Generate unique key for each cell to track processing state
  String _getCellKey(String time, String court) {
    return '${time}_$court';
  }

  // Widget for court cell
  Widget _buildCourtCell(
    String time,
    String court,
    String type,
    bool isAvailable,
    String username,
    bool isClosed,
    bool isHoliday,
  ) {
    bool isPast = _isTimePast(time, selectedDate);
    String cellKey = _getCellKey(time, court);

    void handleTap() async {
      if (loadingCells.contains(cellKey) || isBookingInProgress) {
        showCustomSnackBar(context, 'Mohon tunggu, sedang memproses...');
        return;
      }

      debugPrint('Cell key: $cellKey'); // debug

      try {
        if (isPast) {
          showCustomSnackBar(
            context,
            'Waktu ini sudah lewat, tidak bisa dibooking',
          );
          return;
        }

        if (isClosed) {
          showCustomSnackBar(context, 'Lapangan ditutup pada waktu ini');
          return;
        }

        setState(() {
          loadingCells.add(cellKey);
        });

        debugPrint('Loading cells: $loadingCells'); // debug

        if (!isAvailable) {
          await _showBookingDetails(time, court, type, username);
        } else {
          await _showAddBookingDialog(time, court);
        }
      } finally {
        // Remove loading state
        if (mounted) {
          setState(() {
            loadingCells.remove(cellKey);
          });
        }
      }
    }

    return GestureDetector(
      onTap: loadingCells.contains(cellKey) ? null : handleTap,
      child: Container(
        width: 120,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              isClosed
                  ? closedColor
                  : (isHoliday
                      ? (isAvailable ? holidayColor : bookedColor)
                      : (isAvailable ? availableColor : bookedColor)),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child:
            loadingCells.contains(cellKey)
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isClosed
                          ? 'Tutup'
                          : (isHoliday
                              ? (isAvailable ? 'Hari Libur' : username)
                              : (isAvailable ? 'Tersedia' : username)),
                      style: TextStyle(
                        color:
                            isClosed
                                ? Colors.black
                                : (isHoliday
                                    ? (isAvailable
                                        ? Colors.black
                                        : type == 'member'
                                        ? Colors.blue
                                        : Colors.red)
                                    : (isAvailable
                                        ? Colors.black
                                        : type == 'member'
                                        ? Colors.blue
                                        : Colors.red)),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
      ),
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

  @override
  void initState() {
    super.initState();
    // Load data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrCreateSlots(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedCourtIds = courtIds.toList()..sort((a, b) => a.compareTo(b));
    return Scaffold(
      appBar: AppBar(title: Text("Kalender"),
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
          // Date selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
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
                    ElevatedButton(
                      onPressed: () {
                        _changeDate(
                          selectedDate.subtract(const Duration(days: 1)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        _changeDate(DateTime.now());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Hari Ini'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        _changeDate(selectedDate.add(const Duration(days: 1)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _buildStatusLegend(),

          Expanded(
            child:
                isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading booking data...'),
                        ],
                      ),
                    )
                    // Header row
                    : RefreshIndicator(
                      onRefresh: () async {
                        _loadOrCreateSlots(selectedDate);
                      },
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildHeaderCell('Jam', width: 110),
                                      ...sortedCourtIds.map(
                                        (id) =>
                                            _buildHeaderCell('Lapangan $id'),
                                      ),
                                    ],
                                  ),
                                ),

                                // Data rows
                                ...timeRanges.map((timeRange) {
                                  return Row(
                                    children: [
                                      _buildTimeCell(timeRange),
                                      ...sortedCourtIds.map((courtId) {
                                        final slot = _findSlot(
                                          timeRange,
                                          courtId,
                                        );
                                        return _buildCourtCell(
                                          timeRange,
                                          courtId,
                                          slot?.type ?? 'nonMember',
                                          slot?.isAvailable ?? true,
                                          slot?.username ?? '',
                                          slot?.isClosed ?? false,
                                          slot?.isHoliday ?? false,
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
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clear any loading states
    loadingCells.clear();
    super.dispose();
  }
}
