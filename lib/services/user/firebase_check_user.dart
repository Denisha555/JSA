import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/time_slot/firebase_update_time_slot.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';

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

  Future<void> checkRewardTime(String username) async {
    try {
      if (await checkExistence('username', username)) {
        final userData = await FirebaseGetUser().getUserByUsername(username);
        if (userData[0].startTimePoint != '') {
          final startDate = DateTime.parse(userData[0].startTimePoint);
          final finishDate = DateTime(
            startDate.year,
            startDate.month + 1,
            startDate.day,
          );

          final now = DateTime.now();
          final difference = finishDate.difference(now);
          final daysLeft = difference.inDays;

          if (daysLeft <= 0) {
            await FirebaseUpdateUser().updateUser(
              'startTimePoint',
              username,
              '',
            );
            await FirebaseUpdateUser().updateUser('point', username, 0);
          }
        }
      }
    } catch (e) {
      throw Exception('Error checking reward time: $e');
    }
  }
}
