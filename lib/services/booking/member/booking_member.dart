import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class BookingMember {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> bookSlotForMember(String courtId, String dateStr, String startTime, String username) async {
    try {
      final docId = '${courtId}_$dateStr';
      final doc = await firestore.collection('time_slots').doc(docId).get();

      if (!doc.exists) {
        throw Exception('Slot not found');
      }

      final slots = doc.data()!['slots'] as List<dynamic>;
      final slotIndex = slots.indexWhere((slot) => slot['startTime'] == startTime);

      if (slotIndex == -1 && slots[slotIndex]['isAvailable'] == false && slots[slotIndex]['isClosed'] == true) {
        throw Exception('Slot not available');
      }

      var updatedSlot = List<Map<String, dynamic>>.from(slots);
      updatedSlot[slotIndex]['isAvailable'] = false;
      updatedSlot[slotIndex]['type'] = 'member';
      updatedSlot[slotIndex]['username'] = username;

      await firestore.collection('time_slots').doc(docId).update({
        'slots': updatedSlot,
      });
    } catch (e) {
      throw Exception('Failed to book slot for member: $e');
    }
  }

  // digunakan saat mendaftar sebagai member
  Future<void> addTotalBookingDays(String username, int days, int length) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );
      if (exist) {
        await firestore.collection('users').doc(username).set({
          'memberTotalBooking': FieldValue.increment(days),
          'memberCurrentTotalBooking': FieldValue.increment(days),
          'memberBookingLength': FieldValue.increment(length),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to add total days: $e');
    }
  }

  // digunakan saat melakukan booking ulang di kalender
  Future<void> addTotalBooking(String username) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );
      if (exist) {
        await firestore.collection('users').doc(username).set({
          'memberCurrentTotalBooking': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to add total booking: $e');
    }
  }

  Future<void> addBookingDates(String username, dynamic dates) {
    return firestore.collection('users').doc(username).set({
      'bookingDates': FieldValue.arrayUnion(dates),
    }, SetOptions(merge: true));
  }
}
