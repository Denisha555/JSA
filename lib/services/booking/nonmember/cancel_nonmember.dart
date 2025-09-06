import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class CancelNonMember {
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

    if (!doc.exists) {
      throw Exception('Slot not found');
    }

    final slots = doc.data()!['slots'] as List<dynamic>;
    final slotIndex = slots.indexWhere(
      (slot) => slot['startTime'] == startTime,
    );

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

      await FirebaseCheckUser().checkMembership(username);
      await FirebaseCheckUser().checkRewardTime(username);

      final userRef = userQuery.docs.first.reference;

      var updatedSlot = List<Map<String, dynamic>>.from(slots);

      List<String> cancelList = List<String>.from(
        updatedSlot[slotIndex]['cancel'] ?? [],
      );
      cancelList.add(username);

      updatedSlot[slotIndex]['isAvailable'] = true;
      updatedSlot[slotIndex]['username'] = null;
      updatedSlot[slotIndex]['type'] = null;
      updatedSlot[slotIndex]['cancel'] = cancelList;

      batch.set(firestore.collection('time_slots').doc(docId), {
        'slots': updatedSlot,
      }, SetOptions(merge: true));

      batch.set(userRef, {
        'totalHour': FieldValue.increment(-0.5),
        'point': FieldValue.increment(-0.5),
      }, SetOptions(merge: true));

      await batch.commit();
    } on FirebaseException catch (e) {
      throw 'Error canceling booking: ${e.code}';
    } catch (e) {
      throw 'Error canceling booking: $e';
    }
  }

  Future<void> updateUserCancel(String username, String dateStr) async {
    try {
      final docRef = firestore.collection('users').doc(username);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final List<dynamic> currentDates = data?['bookingDates'] ?? [];

        // Salin dan hapus SATU kemunculan dateStr
        final List<String> updatedDates = List<String>.from(currentDates);
        final index = updatedDates.indexOf(dateStr);
        if (index != -1) {
          updatedDates.removeAt(index);
        }

        await docRef.set({
          'cancel': FieldValue.increment(1),
          'totalBooking': FieldValue.increment(-1),
          'cancelDate': FieldValue.arrayUnion([dateStr]),
          'bookingDates': updatedDates,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to subtract booking: $e');
    }
  }
}
