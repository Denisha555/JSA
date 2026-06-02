import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_update_time_slot.dart';

class FirebaseCheckTimeSlot {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<bool> isSlotAvailable(
    List<String> courtIds,
    List<String> dateStrs,
    String startTime,
    String endTime,
  ) async {
    try {
      int timeCheckTimeSlot = DateTime.now().millisecondsSinceEpoch;
      final futures = <Future<DocumentSnapshot>>[];

      for (final date in dateStrs) {
        for (final court in courtIds) {
          futures.add(
            firestore.collection('time_slots').doc('${court}_$date').get(),
          );
        }
      }

      final docs = await Future.wait(futures);

      final docsMap = <String, DocumentSnapshot>{};

      for (final doc in docs) {
        docsMap[doc.id] = doc;
      }

      for (final date in dateStrs) {
        for (final court in courtIds) {
          final docId = '${court}_$date';

          final doc = docsMap[docId];

          if (doc == null || !doc.exists) {
            await FirebaseAddTimeSlot().addTimeSlot(DateTime.parse(date));
            continue;
          }

          final slots = doc['slots'] as List<dynamic>;

          bool inRange = false;

          for (final slot in slots) {
            if (slot['startTime'] == startTime) {
              inRange = true;
            }

            if (inRange) {
              final available =
                  slot['isAvailable'] == true && slot['isClosed'] != true;

              if (!available) {
                return false;
              }

              if (slot['endTime'] == endTime) {
                break;
              }
            }
          }
        }
      }
      print(
        'Time check time slot: ${(DateTime.now().millisecondsSinceEpoch - timeCheckTimeSlot) / 1000} seconds',
      );
      return true;
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
