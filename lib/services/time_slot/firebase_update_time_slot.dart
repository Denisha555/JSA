import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';

class FirebaseUpdateTimeSlot {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateTimeSlot(String dateStr, String courtId) async {
    try {
      final docId = '${courtId}_$dateStr';
      final docRef = firestore.collection('time_slots').doc(docId);
      final doc = await docRef.get();

      final data = doc.data()!;
      final slots = data['slots'] as List<dynamic>;

      for (var time in timeSlots) {
        final existing = slots.any((slot) => slot['startTime'] == time);

        if (!existing) {
          slots.add({
            'startTime': time,
            'endTime': calculateEndTimeUseStartTime(time),
            'isAvailable': true,
            'username': '',
            'cancel': [],
            'isClosed': false,
            'isHoliday': false,
            'type': '',
          });
        }
      }

      await firestore.collection('time_slots').doc(docId).update({
        'slots': slots, // yang sudah diperbarui tadi
        'status': 'ready', // Update status menjadi 'ready'
      });
    } catch (e) {
      throw Exception('Failed to update time slot: $e');
    }
  }

  Future<void> updateMemberTimeSlots(String username) async {
    try {
      final user = await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (user.docs.isEmpty) {
        throw Exception('User not found');
      } else {
        final memberBookingDate = user.docs[0].get('bookingDates') as List<dynamic>;
        for (var date in memberBookingDate) {
          final timeSlots = await firestore
              .collection('time_slots')
              .where('date', isEqualTo: date)
              .get();

          if (timeSlots.docs.isNotEmpty) {
            for (var slot in timeSlots.docs) {
              final slots = slot.data()['slots'] as List<dynamic>;
              for (var slot in slots) {
                if (slot['username'] == username) {
                  slots[slots.indexOf(slot)] = {
                    ...slot,
                    'status': 'finish'
                  };
                }
              }
              await firestore.collection('time_slots').doc(slot.id).update({
                'slots': slots,
              });
            }
          } else {
            await FirebaseAddTimeSlot().addTimeSlot(DateTime.parse(date));
          }
        }
      }
      
    } catch (e) {
      throw Exception('Failed to update member time slots: $e');
    }
  }
}
