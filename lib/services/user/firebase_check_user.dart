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

  Future<bool> checkExistenceAndActive(String field, dynamic value) async {
    final snapshot =
        await firestore
            .collection('users')
            .where(field, isEqualTo: value)
            .where('status', isEqualTo: '')
            .limit(1)
            .get();
    print(snapshot.docs.isEmpty);
    return snapshot.docs.isNotEmpty;
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

  Future<bool> checkExistenceOther(
    String field,
    dynamic value,
    String username,
  ) async {
    final snapshot =
        await firestore
            .collection('users')
            .where(field, isEqualTo: value)
            .where("username", isNotEqualTo: username)
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

          if (daysLeft < 0) {
            await FirebaseUpdateUser().updateManyData({
              "role": "nonMember",
              "startTimeMember": "",
              "memberTotalBooking": 0,
              "memberCurrentTotalBooking": 0,
              "memberBookingLength": 0,
            }, username);
            // await FirebaseUpdateTimeSlot().updateMemberTimeSlots(username);
          }
        }
      }
    } catch (e) {
      throw Exception('Error checking membership: $e');
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

      List<dynamic> bookingDetailsNeed =
          bookingDetails.where((e) => e['type'] == 'nonMember').toList();

      bookingDetailsNeed.sort(
        (a, b) =>
            DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])),
      );

      String startTimePoint =
          await FirebaseGetUser().getUserData(username, 'startTimePoint') ?? '';

      final now = DateTime.now();

      List<dynamic> relevantBookingDetails = [];
      List<dynamic> needCheckBookings = [];

      // cari startTimePoint jika kosong
      if (startTimePoint.isEmpty) {
        for (final booking in bookingDetailsNeed) {
          final bookingEnd = DateTime.parse(
            '${booking["date"]} ${booking["endTime"].replaceAll(".", ":")}',
          );

          if (booking['status'] != 'checked' && bookingEnd.isBefore(now)) {
            startTimePoint = booking['date'];
            break;
          }
        }

        if (startTimePoint.isEmpty) {
          await FirebaseUpdateUser().updateUser('point', username, 0);
          return;
        }
      }

      DateTime startDate = DateTime.parse(startTimePoint);
      DateTime finishDate = startDate.add(const Duration(days: 30));

      // periode selesai
      if (now.isAfter(finishDate)) {
        startTimePoint = '';

        for (final booking in bookingDetailsNeed) {
          if (booking['status'] == 'checked') continue;

          final bookingDate = DateTime.parse(booking['date']);

          if (bookingDate.isAfter(finishDate)) {
            startTimePoint = booking['date'];
            break;
          }
        }

        if (startTimePoint.isEmpty) {
          await FirebaseUpdateUser().updateUser('point', username, 0);
          return;
        }

        startDate = DateTime.parse(startTimePoint);
        finishDate = startDate.add(const Duration(days: 30));

        await FirebaseUpdateUser().updateUser('point', username, 0);
      }

      for (final booking in bookingDetailsNeed) {
        if (booking['status'] == 'checked') continue;

        final bookingDate = DateTime.parse(booking['date']);

        final bookingEnd = DateTime.parse(
          '${booking["date"]} ${booking["endTime"].replaceAll(".", ":")}',
        );

        // booking belum selesai
        if (bookingEnd.isAfter(now)) continue;

        // masuk periode aktif
        if ((bookingDate.isAtSameMomentAs(startDate) ||
                bookingDate.isAfter(startDate)) &&
            (bookingDate.isAtSameMomentAs(finishDate) ||
                bookingDate.isBefore(finishDate))) {
          relevantBookingDetails.add(booking);
        }
        // booking lama yang belum pernah diproses
        else if (bookingDate.isBefore(startDate)) {
          needCheckBookings.add(booking);
        }
      }

      // booking periode aktif
      for (final booking in relevantBookingDetails) {
        String startTime = booking['startTime'].toString().replaceAll('.', ':');

        String endTime = booking['endTime'].toString().replaceAll('.', ':');

        final date = booking['date'];

        final start = DateTime.parse('$date $startTime');
        final end = DateTime.parse('$date $endTime');

        final durationInHours = end.difference(start).inMinutes / 60;

        point += durationInHours;
        hour += durationInHours;
        totalBooking++;

        booking['status'] = 'checked';
      }

      // booking lama yang tertinggal
      for (final booking in needCheckBookings) {
        String startTime = booking['startTime'].toString().replaceAll('.', ':');

        String endTime = booking['endTime'].toString().replaceAll('.', ':');

        final date = booking['date'];

        final start = DateTime.parse('$date $startTime');
        final end = DateTime.parse('$date $endTime');

        final durationInHours = end.difference(start).inMinutes / 60;

        hour += durationInHours;
        totalBooking++;

        booking['status'] = 'checked';
      }

      await FirebaseUpdateUser().updateUser(
        'bookingDates',
        username,
        bookingDetails,
      );

      if (point > 0) {
        await FirebaseUpdateUser().updateUser(
          'point',
          username,
          FieldValue.increment(point),
        );
      }

      if (hour > 0) {
        await FirebaseUpdateUser().updateUser(
          'hour',
          username,
          FieldValue.increment(hour),
        );
      }

      if (totalBooking > 0) {
        await FirebaseUpdateUser().updateUser(
          'totalBooking',
          username,
          FieldValue.increment(totalBooking),
        );
      }

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
