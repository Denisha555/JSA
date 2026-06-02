import 'package:flutter_application_1/services/user/firebase_get_user.dart';
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
      int timeGetTimeSlot = DateTime.now().millisecondsSinceEpoch;
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      final querySnapshot =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .get();

      if (querySnapshot.docs.isEmpty) {
        int timeAddTimeSlot = DateTime.now().millisecondsSinceEpoch;
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);
        print('Time to add time slot: ${DateTime.now().millisecondsSinceEpoch - timeAddTimeSlot} ms');
        return getTimeSlot(selectedDate);
      }

      // Kumpulkan semua userId unik
      final Set<String> userIds = {};

      for (final doc in querySnapshot.docs) {
        final slots = doc.data()['slots'] as List<dynamic>;

        for (final slot in slots) {
          final userId = slot['userId'];

          if (userId != null && userId.toString().isNotEmpty) {
            userIds.add(userId.toString());
          }
        }
      }

      // Buat map userId -> username
      Map<String, String> userMap = {};

      if (userIds.isNotEmpty) {
        final usersSnapshot =
            await firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: userIds.toList())
                .get();

        userMap = {
          for (final doc in usersSnapshot.docs)
            doc.id: doc.data()['username'] as String,
        };
      }

      // Generate result
      List<TimeSlotModel> result = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        final courtId = data['courtId'] as String;
        final date = data['date'] as String;
        final slots = data['slots'] as List<dynamic>;

        result.addAll(
          slots.map((slot) {
            final slotData = Map<String, dynamic>.from(slot);

            final userId = slotData['userId'];

            if (userId != null && userId.toString().isNotEmpty) {
              slotData['username'] = userMap[userId.toString()] ?? '';
            }

            return TimeSlotModel.fromJson(
              slotData,
              courtId: courtId,
              date: date,
            );
          }),
        );
      }
      print('Time to get time slot: ${DateTime.now().millisecondsSinceEpoch - timeGetTimeSlot} ms');
      return result;
    } catch (e) {
      throw Exception('Failed to get time slots: $e');
    }
  }

  Future<List<TimeSlotModel>> getSpesificTimeSlots(
    String selectedDate,
    String courtId,
  ) async {
    try {
      final docId = '${courtId}_$selectedDate';
      final doc = await firestore.collection('time_slots').doc(docId).get();

      if (!doc.exists) {
        await FirebaseAddTimeSlot().addTimeSlot(DateTime.parse(selectedDate));
        return getSpesificTimeSlots(selectedDate, courtId);
      }

      final slots = doc.data()!['slots'] as List<dynamic>;

      return await Future.wait(
        slots.map((slot) async {
          Map<String, dynamic> slotData = Map<String, dynamic>.from(slot);
          if (slotData['userId'] != null && slotData['userId'] != '') {
            String username = await FirebaseGetUser().getUserDataById(
              slotData['userId'],
              'username',
            );
            slotData['username'] = username;
          }

          return TimeSlotModel.fromJson(
            slotData,
            courtId: courtId,
            date: selectedDate,
          );
        }),
      );
    } catch (e) {
      throw Exception('Failed to get time slots by court: $e');
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
      final docId = '${court}_$dateStr';
      final doc = await firestore.collection('time_slots').doc(docId).get();

      if (!doc.exists) {
        await FirebaseAddTimeSlot().addTimeSlot(date);
        return getSlotRangeAvailability(
          startTime: startTime,
          court: court,
          date: date,
          maxSlots: maxSlots,
        );
      }

      final slots = doc.data()!['slots'] as List<dynamic>;
      final startMinutes = timeToMinutes(startTime);

      // PERBAIKAN: Filter dan urutkan slot dengan benar
      return slots
          .where((slot) {
            final slotStart = timeToMinutes(slot['startTime']);
            return slotStart >= startMinutes; // Ambil slot dari waktu mulai
          })
          .take(maxSlots) // Batasi jumlah slot
          .map(
            (slot) =>
                TimeSlotModel.fromJson(slot, courtId: court, date: dateStr),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get slot range availability: $e');
    }
  }
}
