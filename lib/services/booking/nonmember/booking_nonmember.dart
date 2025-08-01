import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class BookingNonMember {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> bookSlotForNonMember(
    String courtId,
    String dateStr,
    String startTime,
    String username,
    double totalHours,
  ) async {
    try {
      final docId = '${courtId}_$dateStr';
      final doc = await firestore.collection('time_slots').doc(docId).get();

      if (!doc.exists) {
        throw Exception('Slot not found');
      }

      final slots = doc.data()!['slots'] as List<dynamic>;
      final slotIndex = slots.indexWhere((slot) => slot['startTime'] == startTime);

      if (slotIndex == -1 || !slots[slotIndex]['isAvailable'] || slots[slotIndex]['isClosed'] == true) {
        throw Exception('Slot not available');
      }

      var updatedSlot = List<Map<String, dynamic>>.from(slots);
      updatedSlot[slotIndex]['isAvailable'] = false;
      updatedSlot[slotIndex]['type'] = 'nonMember';
      updatedSlot[slotIndex]['username'] = username;

      await firestore.collection('time_slots').doc(docId).update({
        'slots': updatedSlot,
      });
    } catch (e) {
      throw Exception('Failed to book slots for non-member: $e');
    }
  }

  Future<void> addTotalBooking(String username) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );
      if (exist) {
        await firestore.collection('users').doc(username).set({
          'totalBooking': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to add total booking: $e');
    }
  }

  Future<void> addBookingDates (String username, dynamic dates) async {
    return firestore.collection('users').doc(username).set({
      'bookingDates': FieldValue.arrayUnion(dates),
    }, SetOptions(merge: true));
  }
}
