import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteHoliday {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> deleteHoliday(String selectedDate) async {
    try {
      await firestore
          .collection('jadwal_khusus')
          .where('date', isEqualTo: selectedDate)
          .limit(1)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });

      final docId =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: selectedDate)
              .get();

      if (docId.docs.isEmpty) {
        throw Exception('No time slots found for the selected date.');
      } else {
        final List<Map<String, dynamic>> updatedSlots = [];
        for (var doc in docId.docs) {
          final slots = doc.data()['slots'] as List<dynamic>;
          for (var slot in slots) {
            var updatedSlot = Map<String, dynamic>.from(slot);
            updatedSlot['isHoliday'] = false;
            updatedSlots.add(updatedSlot);
          }
          doc.reference.set({'slots': updatedSlots}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      throw Exception('Failed to delete holiday: $e');
    }
  }
}
