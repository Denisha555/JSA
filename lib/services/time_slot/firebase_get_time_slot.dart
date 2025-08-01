import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_check_time_slot.dart';


class FirebaseGetTimeSlot {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<TimeSlotModel>> getTimeSlot(DateTime selectedDate) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final querySnapshot =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .get();

      if (querySnapshot.docs.isEmpty) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);
        return getTimeSlot(selectedDate);
      }

      // await FirebaseCheckTimeSlot().isSlotReady(dateStr); 

      List<TimeSlotModel> result = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final courtId = data['courtId'] as String;
        final date = data['date'] as String;
        final slots = data['slots'] as List<dynamic>;
        result.addAll(
          slots.map(
            (slot) =>
                TimeSlotModel.fromJson(slot, courtId: courtId, date: date),
          ),
        );
      }
      return result;
    } catch (e) {
      throw Exception('Failed to get time slots: $e');
    }
  }

  Future<List<TimeSlotModel>> getAvailableSlots(
    DateTime selectedDate,
    String startTime,
    String endTime,
    String courtId,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final docId = '${courtId}_$dateStr';
      final doc = await firestore.collection('time_slots').doc(docId).get();

      if (!doc.exists) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);
        return getAvailableSlots(selectedDate, startTime, endTime, courtId);
      }

      final slots = doc.data()!['slots'] as List<dynamic>;
      final startMinutes = timeToMinutes(startTime);
      final endMinutes = timeToMinutes(endTime);

      return slots
          .where((slot) {
            final slotStart = timeToMinutes(slot['startTime']);
            return slotStart >= startMinutes &&
                slotStart < endMinutes &&
                slot['isAvailable'] == true &&
                !(slot['isClosed'] ?? false) &&
                !(slot['isHoliday'] ?? false);
          })
          .map(
            (slot) =>
                TimeSlotModel.fromJson(slot, courtId: courtId, date: dateStr),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get available time slots: $e');
    }
  }

  Future<List<TimeSlotModel>> getSlotRangeAvailability({
    required String startTime,
    required String court,
    required DateTime date,
    required int maxSlots,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final query = firestore
          .collection('time_slots')
          .where('date', isEqualTo: dateStr)
          .where('courtId', isEqualTo: court);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // Ambil array "slots" dari dokumen pertama
      final slots = List<Map<String, dynamic>>.from(
        snapshot.docs.first.data()['slots'],
      );

      // Filter berdasarkan startTime dan ketersediaan
      final filtered =
          slots
              .where(
                (slot) =>
                    slot['startTime'].compareTo(startTime) >= 0 &&
                    slot['isAvailable'] == true,
              )
              .take(maxSlots)
              .map(
                (slot) => TimeSlotModel(
                  startTime: slot['startTime'],
                  endTime: slot['endTime'],
                  isAvailable: slot['isAvailable'],
                  isClosed: slot['isClosed'] ?? false,
                ),
              )
              .toList();

      return filtered;
    } catch (e) {
      throw Exception('Failed to get slot range availability: $e');
    }
  }

  Future<List<TimeSlotModel>> getCancelTimeSlots(String username) {
    try {
      return firestore
          .collection('time_slots')
          .where('username', isEqualTo: username)
          .get()
          .then(
            (snapshot) =>
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  return TimeSlotModel(
                    date: data['date'],
                    startTime: data['startTime'],
                    endTime: data['endTime'],
                  );
                }).toList(),
          );
    } catch (e) {
      throw Exception('Failed to get cancel time slots: $e');
    }
  }
}
