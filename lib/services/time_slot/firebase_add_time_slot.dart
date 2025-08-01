import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';

class FirebaseAddTimeSlot {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addTimeSlot(DateTime selectedDate) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      print('Adding time slots for $dateStr');

      final courts = await firestore.collection('lapangan').limit(10).get();
      if (courts.docs.isEmpty) throw Exception('No courts found');

      var batch = firestore.batch();
      List<String> createdDocIds = [];
      int operationCount = 0;
      const maxBatchSize = 1;

      for (final court in courts.docs) {
        final courtId = court['nomor'] as String?;
        if (courtId == null) continue;

        final docId = '${courtId}_$dateStr';
        final existingDoc =
            await firestore.collection('time_slots').doc(docId).get();
        if (existingDoc.exists) continue;

        final slots =
            timeSlots.map((startTime) {
              return {
                'startTime': startTime,
                'endTime': calculateEndTimeUseStartTime(startTime),
                'isAvailable': true,
                'username': '',
                'cancel': [],
                'isClosed': false,
                'isHoliday': false,
                'type': '',
              };
            }).toList();

        // Step 1: Buat dengan status 'pending'
        batch.set(firestore.collection('time_slots').doc(docId), {
          'courtId': courtId,
          'date': dateStr,
          'slots': slots,
          'status': 'pending',
        });

        createdDocIds.add(docId);
        operationCount++;

        if (operationCount >= maxBatchSize) {
          await batch.commit();
          batch = firestore.batch();
          operationCount = 0;
        }
      }

      // Commit sisa batch
      if (operationCount > 0) {
        await batch.commit();
      }

      // Step 2: Update semua status ke 'ready' (pakai batch lagi)
      print('Updating status to ready...');
      batch = firestore.batch();
      for (final docId in createdDocIds) {
        final ref = firestore.collection('time_slots').doc(docId);
        batch.update(ref, {'status': 'ready'});
      }
      await batch.commit();

      print('All time slots successfully added and marked as ready.');
    } catch (e) {
      print('Error in addTimeSlot: $e');
      throw Exception('Failed to add time slots: $e');
    }
  }
}
