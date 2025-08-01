import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';

class AddCloseDay {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<void> closeUseTimeRange(
    DateTime selectedDate,
    String startTime,
    String endTime,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final courts = await firestore.collection('lapangan').get();
      final batch = firestore.batch();

      final isDateInitialized =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .limit(1)
              .get();

      if (isDateInitialized.docs.isEmpty) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);
      }

      final startMins = timeToMinutes(startTime);
      final endMins = timeToMinutes(endTime);

      for (final court in courts.docs) {
        final courtNumber = court['nomor'];

        for (int mins = startMins; mins < endMins; mins += 30) {
          final docId = '${courtNumber}_$dateStr';
          final doc = await firestore.collection('time_slots').doc(docId).get();

          if (!doc.exists) {
            throw Exception('Slot not found');
          }

          final slots = doc.data()!['slots'] as List<dynamic>;
          final slotIndex = slots.indexWhere(
            (slot) => slot['startTime'] == startTime,
          );

          if (slotIndex == -1 ||
              !slots[slotIndex]['isAvailable'] ||
              slots[slotIndex]['isClosed'] == true ||
              slots[slotIndex]['isHoliday'] == true) {
            throw Exception('Slot not available');
          }

          await firestore.collection('time_slots').doc(docId).set({
            'slots[$slotIndex].isAvailable': false,
            'slots[$slotIndex].isClosed': true,
          }, SetOptions(merge: true));
        }
      }

      final closeDayRef = firestore.collection('jadwal_khusus').doc();
      batch.set(closeDayRef, {
        'date': dateStr,
        'startTime': startTime,
        'endTime': endTime,
        'type': 'closed',
        'description': 'time range',
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to close range: ${e.toString()}');
    }
  }

  Future<void> closeAllDay(DateTime selectedDate) async {
    try {
      final targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

      // Cek apakah sudah ada slot di tanggal ini
      var existingSlots =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .get();

      if (existingSlots.docs.isEmpty) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);

        existingSlots =
            await firestore
                .collection('time_slots')
                .where('date', isEqualTo: dateStr)
                .get();
      }

      var updateBatch = firestore.batch();
      int updateCount = 0;
      const maxBatchSize = 500;
      List<Map<String, dynamic>> updatedSlots = [];

      for (var doc in existingSlots.docs) {
        final slots = doc.data()['slots'] as List<dynamic>;
        for (var slot in slots) {
          var updatedSlot = Map<String, dynamic>.from(slot);
          updatedSlot['isClosed'] = true;
          updatedSlot['isAvailable'] = false;
          updatedSlots.add(updatedSlot);
        }
        
        updateBatch.set(doc.reference, {
          'slots': updatedSlots,
        }, SetOptions(merge: true));

        updateCount++;

        if (updateCount >= maxBatchSize) {
          await updateBatch.commit();
          updateBatch = firestore.batch();
          updateCount = 0;
        }
      }

      if (updateCount > 0) {
        await updateBatch.commit();
      }

      // Tambahkan catatan ke koleksi closed_days
      await firestore.collection('jadwal_khusus').add({
        'date': dateStr,
        'startTime': '07:00',
        'endTime': '23:00',
        'description': 'all day',
        'type': 'closed',
      });
    } catch (e) {
      throw Exception('Failed to close all day: $e');
    }
  }
}
