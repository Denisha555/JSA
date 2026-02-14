import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_get_time_slot.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';

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
      final user =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      if (user.docs.isEmpty) {
        throw Exception('User not found');
      } else {
        final memberBookingDate =
            user.docs[0].get('bookingDates') as List<dynamic>;
        for (var date in memberBookingDate) {
          final timeSlots =
              await firestore
                  .collection('time_slots')
                  .where('date', isEqualTo: date)
                  .get();

          if (timeSlots.docs.isNotEmpty) {
            for (var slot in timeSlots.docs) {
              final slots = slot.data()['slots'] as List<dynamic>;
              for (var slot in slots) {
                if (slot['username'] == username) {
                  slots[slots.indexOf(slot)] = {...slot, 'status': 'finish'};
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

  Future<void> updateUsernameTimeSlots(
    String oldUsername,
    String newUsername,
  ) async {
    try {
      final bookedDates =
          await FirebaseGetUser().getUserData(
                newUsername.trim(),
                'bookingDates',
              )
              as List<dynamic>?;
      
      if (bookedDates == null || bookedDates.isEmpty) return;

      final slotsFutures =
          bookedDates
              .map(
                (date) =>
                    FirebaseGetTimeSlot().getTimeSlot(DateTime.parse(date)),
              )
              .toList();

      final allSlotsArrays = await Future.wait(slotsFutures);

      final updatesByDoc = {};

      for (int i = 0; i < bookedDates.length; i++) {
      final date = bookedDates[i].toString();
      final slots = allSlotsArrays[i];
      
      for (var slot in slots) {
        if (slot.username == oldUsername) {
          final key = '${slot.courtId}_${slot.date}';
          
          // Ambil dokumen Firestore-nya
          if (!updatesByDoc.containsKey(key)) {
            final docSnapshot = await firestore
                .collection('time_slots')
                .where('date', isEqualTo: slot.date)
                .where('courtId', isEqualTo: slot.courtId)
                .limit(1)
                .get();
            
            if (docSnapshot.docs.isNotEmpty) {
              final slotsData = docSnapshot.docs.first.data()['slots'];
              updatesByDoc[key] = [
                docSnapshot.docs.first,
                List<Map<String, dynamic>>.from(slotsData ?? [])
              ];
            }
          }
          
          // Update slot di memory
          final docData = updatesByDoc[key];
          if (docData != null) {
            final slotsList = docData[1] as List<Map<String, dynamic>>;
            for (var timeSlot in slotsList) {
              if (timeSlot['startTime'] == slot.startTime && 
                  timeSlot['username'] == oldUsername) {
                timeSlot['username'] = newUsername;
              }
            }
          }
        }
      }
    }
    
    // 4. 🔥 Batch update semua dokumen yang berubah
    final batch = firestore.batch();
    for (var entry in updatesByDoc.entries) {
      final doc = entry.value[0] as DocumentSnapshot;
      final updatedSlots = entry.value[1] as List;
      batch.update(doc.reference, {'slots': updatedSlots});
    }
    
    await batch.commit();

    } catch (e) {
      throw Exception('Failed to update username in time slots: $e');
    }
  }
}
