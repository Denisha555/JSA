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

      print('start time : $startTime');

      final slots = doc.data()!['slots'] as List<dynamic>;
      final slotIndex = slots.indexWhere(
        (slot) => slot['startTime'] == startTime,
      );

      await FirebaseCheckUser().checkMembership(username);
      await FirebaseCheckUser().checkRewardTime(username);

      var updatedSlot = List<Map<String, dynamic>>.from(slots);

      List<String> cancelList = List<String>.from(
        updatedSlot[slotIndex]['cancel'] ?? [],
      );

      cancelList.add(username);

      updatedSlot[slotIndex]['isAvailable'] = true;
      updatedSlot[slotIndex]['username'] = '';
      updatedSlot[slotIndex]['type'] = '';
      updatedSlot[slotIndex]['cancel'] = cancelList;

      batch.set(firestore.collection('time_slots').doc(docId), {
        'slots': updatedSlot,
      }, SetOptions(merge: true));

      batch.commit();
    } catch (e) {
      throw 'Error canceling booking: $e';
    }
  }

  Future<void> updateUserCancel(String username, String dateStr) async {
    try {
      final docRef = firestore.collection('users').doc(username);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        List<dynamic> currentDates = docSnapshot.data()?['bookingDates'] ?? [];

        // Buat salinan & hapus satu kemunculan dateStr
        List<String> updatedDates = List<String>.from(currentDates);
        int indexToRemove = updatedDates.indexOf(dateStr);
        if (indexToRemove != -1) {
          updatedDates.removeAt(indexToRemove);
        }

        await docRef.set({
          'cancel': FieldValue.increment(1),
          'cancelDate': FieldValue.arrayUnion([dateStr]),
          'bookingDates': updatedDates,
          'memberCurrentTotalBooking': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Error updating user cancel: $e');
    }
  }
}
