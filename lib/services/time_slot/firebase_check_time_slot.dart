import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_update_time_slot.dart';


class FirebaseCheckTimeSlot {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<bool> isSlotAvailable(
    String courtId,
    String dateStr,
    String startTime,
  ) async {
    try {
      final docId = '${courtId}_$dateStr';
      final doc = await firestore.collection('time_slots').doc(docId).get();

      print(startTime);

      if (!doc.exists) {
        await FirebaseAddTimeSlot().addTimeSlot(DateTime.parse(dateStr));
        return isSlotAvailable(courtId, dateStr, startTime);
      }

      final slots = doc.data()!['slots'] as List<dynamic>;
      final slot = slots.firstWhere(
        (slot) => slot['startTime'] == startTime,
        orElse: () => throw Exception('Slot not found'),
      );

      return slot['isAvailable'] && !(slot['isClosed'] ?? false);
    } catch (e) {
      throw Exception('Failed to check slot availability: $e');
    }
  }

  Future<bool> hasExistingSlots(String courtNumber, String dateStr) async {
    final docId = '${courtNumber}_$dateStr';
    final doc = await firestore.collection('time_slots').doc(docId).get();
    return doc.exists;
  }

  Future<bool> checkTimeSlots(DateTime date, String startTime) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final QuerySnapshot querySnapshot =
        await firestore
            .collection('time_slots')
            .where('date', isEqualTo: dateStr)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final data = doc.data()! as Map<String, dynamic>;
      final slots = data['slots'] as List<dynamic>;
      final slotExists = slots.any((slot) => slot['startTime'] == startTime);
      return slotExists;
    } else {
      await FirebaseAddTimeSlot().addTimeSlot(DateTime.parse(dateStr));
      return checkTimeSlots(date, startTime);
    }
  }

  Future<void> isSlotReady(String dateStr) async {
    final querySnapshot =
        await firestore
            .collection('time_slots')
            .where('date', isEqualTo: dateStr)
            .get();

    if (querySnapshot.docs.isEmpty) {
      await FirebaseAddTimeSlot().addTimeSlot(DateTime.parse(dateStr));
    } else {
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'ready') {
          continue;
        } else if (data['status'] == 'pending') {
          // Update status menjadi 'ready'
          await FirebaseUpdateTimeSlot().updateTimeSlot(
            dateStr,
            data['courtId'],
          );
        }
      }
    }
  }
}
