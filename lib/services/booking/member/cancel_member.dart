import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class CancelMember {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> cancelBooking(
    String username,
    String dateStr,
    String courtId,
    String startTime,
    String endTime,
  ) async {
    final batch = firestore.batch();
    final docId = '${courtId}_$dateStr';
    final doc = await firestore.collection('time_slots').doc(docId).get();

    try {
      final userQuery =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('user not found');
      }

      if (!doc.exists) {
        throw Exception('slot not found');
      }

      final slots = doc.data()!['slots'] as List<dynamic>;
      final slotIndex = slots.indexWhere(
        (slot) => slot['startTime'] == startTime,
      );

      await FirebaseCheckUser().checkMembership(username);
      await FirebaseCheckUser().checkRewardTime(username);

      var updatedSlot = List<Map<String, dynamic>>.from(slots);

      updatedSlot[slotIndex]['isAvailable'] = true;
      updatedSlot[slotIndex]['username'] = null;
      updatedSlot[slotIndex]['type'] = null;
      updatedSlot[slotIndex]['cancel'] = [
        updatedSlot[slotIndex]['cancel']..add(username),
      ];

      batch.set(firestore.collection('time_slots').doc(docId), {
        'slots': updatedSlot,
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Error canceling booking: $e';
    }
  }

  Future<void> updateUserCancel(username, String dateStr) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );
      if (exist) {
        await firestore.collection('users').doc(username).set({
          'cancel': FieldValue.increment(1),
          'memberCurrentTotalBooking': FieldValue.increment(-1),
          'cancelDate': FieldValue.arrayUnion([dateStr]),
          'bookingDates': FieldValue.arrayRemove([dateStr]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Error updating user cancel: $e');
    }
  }
}
