import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/time_slot/firebase_get_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_update_time_slot.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';
import 'package:intl/intl.dart';

class FirebaseCheckUser {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<String> checkUserType(String username) async {
    try {
      if (await checkExistence('username', username)) {
        final userData = await FirebaseGetUser().getUserByUsername(username);
        return userData[0].role;
      } else {
        return 'not found';
      }
    } catch (e) {
      throw Exception('Error checking user type: $e');
    }
  }

  Future<bool> checkPassword(String userName, String password) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot =
          await users
              .where('username', isEqualTo: userName)
              .where('password', isEqualTo: password)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  Future<bool> checkExistence(String field, dynamic value) async {
    final snapshot =
        await firestore
            .collection('users')
            .where(field, isEqualTo: value)
            .limit(1)
            .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> checkMembership(String username) async {
    try {
      if (await checkExistence('username', username)) {
        final userData = await FirebaseGetUser().getUserByUsername(username);

        if (userData[0].role == 'member') {
          final startDate = DateTime.parse(userData[0].startTimeMember);
          final finishDate = DateTime(startDate.year, startDate.month + 1, 0);

          final now = DateTime.now();
          final difference = finishDate.difference(now);
          final daysLeft = difference.inDays;

          if (daysLeft <= 0) {
            await FirebaseUpdateUser().updateUser(
              'role',
              username,
              'nonMember',
            );
            await FirebaseUpdateUser().updateUser(
              'startTimeMember',
              username,
              FieldValue.delete(),
            );
            await FirebaseUpdateUser().updateUser(
              'memberTotalBooking',
              username,
              FieldValue.delete(),
            );
            await FirebaseUpdateUser().updateUser(
              'memberCurrentTotalBooking',
              username,
              FieldValue.delete(),
            );
            await FirebaseUpdateUser().updateUser(
              'memberBookingLength',
              username,
              FieldValue.delete(),
            );
            await FirebaseUpdateTimeSlot().updateMemberTimeSlots(username);
          }
        }
      }
    } catch (e) {
      throw Exception('Error checking membership: $e');
    }
  }

  Future<void> checkRewardTime(String username, {String date = ''}) async {
    try {
      if (await checkExistence('username', username)) {
        final startTimePoint = await FirebaseGetUser().getUserData(
          username,
          'startTimePoint',
        );

        print('start time point: $startTimePoint');

        if (startTimePoint != '' && startTimePoint != null) {
          final startDate = DateTime.parse(startTimePoint);
          final finishDate = DateTime(
            startDate.year,
            startDate.month + 1,
            startDate.day,
          );
          print('finish date: $finishDate');

          final now = DateTime.now();
          final difference = finishDate.difference(now);
          final daysLeft = difference.inDays;

          print('days left: $daysLeft');

          if (daysLeft <= 0) {
            await FirebaseUpdateUser().updateUser(
              'startTimePoint',
              username,
              '',
            );
            await FirebaseUpdateUser().updateUser('point', username, 0);
          }
        } else if (startTimePoint == '' || startTimePoint == null) {
          print('setting new start time point');
          await FirebaseUpdateUser().updateUser(
            'startTimePoint',
            username,
            date,
          );
        }
      }
    } catch (e) {
      throw Exception('Error checking reward time: $e');
    }
  }

  Future<void> checkUserPoint(String username) async {
    try {
      if (!await checkExistence('username', username)) return;

      double point = 0;
      int totalBooking = 0;
      double hour = 0.0;

      List<dynamic> bookingDetails = await FirebaseGetUser().getUserData(
        username,
        'bookingDates',
      );
      List<String> bookings =
          List<Map<String, dynamic>>.from(
            bookingDetails,
          ).map((e) => e['date'].toString()).toList();

      List<dynamic> relevantBookingDetails = [];

      String startTimePoint =
          await FirebaseGetUser().getUserData(username, 'startTimePoint') ?? '';

      final now = DateTime.now();

      // kalau startTimePoint kosong cari booking bulan ini
      if (startTimePoint.isEmpty) {
        bookings.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

        for (final date in bookings) {
          final parsed = DateTime.parse(date);

          if (parsed.month == now.month && parsed.year == now.year) {
            startTimePoint = date;
            break;
          }
        }

        // tidak ada booking bulan ini
        if (startTimePoint.isEmpty) {
          await FirebaseUpdateUser().updateUser('point', username, 0);
          return;
        }
      }

      DateTime startDate = DateTime.parse(startTimePoint);

      DateTime finishDate = DateTime(
        startDate.year,
        startDate.month + 1,
        startDate.day,
      );

      // kalau periode sudah lewat
      if (DateTime.now().isAfter(finishDate)) {
        startTimePoint = '';

        // cari booking bulan berikutnya
        for (final date in bookings) {
          final parsed = DateTime.parse(date);
          if (parsed.isAfter(finishDate) &&
              parsed.month == now.month &&
              parsed.year == now.year) {
            startTimePoint = date;
            break;
          }
        }

        // tidak ada booking bulan berikutnya
        if (startTimePoint.isEmpty) {
          await FirebaseUpdateUser().updateUser('point', username, 0);
          return;
        }

        // reset periode baru
        startDate = DateTime.parse(startTimePoint);

        finishDate = DateTime(
          startDate.year,
          startDate.month + 1,
          startDate.day,
        );

        // reset point per periode baru
        point = 0;
        await FirebaseUpdateUser().updateUser('point', username, 0);
      }

      final totalDays = finishDate.difference(startDate).inDays;

      for (int i = 0; i < totalDays; i++) {
        final currentDate = startDate.add(Duration(days: i));

        final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

        // skip kalau tidak ada booking
        if (!bookings.contains(dateStr)) continue;

        for (final booking in bookingDetails) {
          if (booking['date'] == dateStr) {
            final bookingEnd = DateTime.parse(
              '$dateStr ${booking["endTime"].replaceAll('.', ':')}',
            );

            if (bookingEnd.isAfter(now)) {
              continue;
            }

            relevantBookingDetails.add(booking);
          }
        }
      }

      for (final booking in relevantBookingDetails) {
        final court = booking['court'];
        String startTime = booking['startTime'];
        String endTime = booking['endTime'];
        final date = booking['date'];
        final status = booking['status'];

        if (status == 'checked') {
          continue;
        }

        startTime = startTime.replaceAll('.', ':');
        endTime = endTime.replaceAll('.', ':');

        final start = DateTime.parse('$date $startTime');
        final end = DateTime.parse('$date $endTime');

        final duration = end.difference(start);
        final durationInHours = duration.inMinutes / 60;

        totalBooking += 1;
        point += durationInHours;
        hour += durationInHours;

        booking['status'] = 'checked';
      }

      await FirebaseUpdateUser().updateUser(
        'bookingDates',
        username,
        bookingDetails,
      );

      await FirebaseUpdateUser().updateUser(
        'point',
        username,
        FieldValue.increment(point),
      );

      await FirebaseUpdateUser().updateUser(
        'totalBooking',
        username,
        FieldValue.increment(totalBooking),
      );

      await FirebaseUpdateUser().updateUser(
        'hour',
        username,
        FieldValue.increment(hour),
      );

      await FirebaseUpdateUser().updateUser(
        'startTimePoint',
        username,
        startTimePoint,
      );
    } catch (e) {
      throw Exception('Error checking user point: $e');
    }
  }

  Future<List<String>> getUserBookingDates(String username) async {
    try {
      if (await checkExistence('username', username)) {
        final userData = await FirebaseGetUser().getUserByUsername(username);
        return userData[0].bookingDates
            .map((date) => date['date'] as String)
            .toList();
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      throw Exception('Error getting user booking dates: $e');
    }
  }
}
