import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';

class FirebaseAddTimeSlot {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addTimeSlot(DateTime selectedDate) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      print('Adding time slots for $dateStr');

      final courts = await firestore.collection('lapangan').get();
      if (courts.docs.isEmpty) throw Exception('No courts found');

      final existingSlots =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .get();

      final existingIds = existingSlots.docs.map((e) => e.id).toSet();

      WriteBatch batch = firestore.batch();

      for (final court in courts.docs) {
        final docId = '${court['nomor']}_$dateStr';

        if (existingIds.contains(docId)) continue;

        batch.set(firestore.collection('time_slots').doc(docId), {
          'courtId': court['nomor'],
          'date': dateStr,
          'slots': List.from(defaultTimeSlots),
          'status': 'ready',
        });
      }

      await batch.commit();   
      } catch (e) {
      print('Error in addTimeSlot: $e');
      throw Exception('Failed to add time slots: $e');
    }
  }
}
