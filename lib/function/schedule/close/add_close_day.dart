import 'package:flutter_application_1/services/notification/onesignal_send_notification.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';
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
      print(dateStr);

      final isDateInitialized =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .get();

      print('Courts count: ${courts.docs.length}');
      print('Initialized slots count: ${isDateInitialized.docs.length}');

      if (isDateInitialized.docs.length != courts.docs.length) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);
      }

      final startMins = timeToMinutes(startTime);
      final endMins = timeToMinutes(endTime);
      print('Start mins: $startMins, End mins: $endMins');

      for (final court in courts.docs) {
        final courtNumber = court['nomor'];
        final docId = '${courtNumber}_$dateStr';

        final doc = await firestore.collection('time_slots').doc(docId).get();
        final slots = doc.data()!['slots'] as List<dynamic>;
        print('Processing court: $courtNumber');

        Map<String, double> pointDeduction = {};
        Map<String, double> totalHourDeduction = {};
        Map<String, double> totalBookingDeduction = {};
        Map<String, List<String>> removedBookingDates = {};

        var beforeUserId = "";

        for (int mins = startMins; mins < endMins; mins += 30) {
          String start = minutesToFormattedTime(mins);
          String end = minutesToFormattedTime(mins + 30);

          if (!doc.exists) {
            throw Exception('Slot not found');
          }

          final slotIndex = slots.indexWhere(
            (slot) => slot['startTime'] == start,
          );

          String userId = slots[slotIndex]['userId'] ?? "";

          if (userId.isNotEmpty) {
            pointDeduction[userId] = (pointDeduction[userId] ?? 0) + 0.5;
            totalHourDeduction[userId] =
                (totalHourDeduction[userId] ?? 0) + 0.5;
            removedBookingDates[userId] =
                (removedBookingDates[userId] ?? []) + [dateStr];

            if (beforeUserId != userId) {
              totalBookingDeduction[userId] =
                  (totalBookingDeduction[userId] ?? 0) + 1;
            }

            beforeUserId = userId;
          }
          slots[slotIndex]['isClosed'] = true;
          slots[slotIndex]['isAvailable'] = false;
        }

        for (var userId in pointDeduction.keys) {
          final username = await FirebaseGetUser().getUserDataById(
            userId,
            'username',
          );
          await FirebaseUpdateUser().updateUser(
            'point',
            username,
            FieldValue.increment(-pointDeduction[userId]!),
          );
          await FirebaseUpdateUser().updateUser(
            'totalHour',
            username,
            FieldValue.increment(-totalHourDeduction[userId]!),
          );
          await FirebaseUpdateUser().updateUser(
            'totalBooking',
            username,
            FieldValue.increment(-totalBookingDeduction[userId]!),
          );
          List<String> bookingDates = List<String>.from(await FirebaseGetUser().getUserData(username, 'bookingDates') ?? []);
          String removedDate = removedBookingDates[userId]!.first;
          bookingDates.remove(removedDate);
          
          await FirebaseUpdateUser().updateUser(
            'bookingDates',
            username,
            bookingDates,
          );

          await OnesignalSendNotificationCustomers().sendNotification(
            "Perubahan Jadwal",
            'Booking Anda pada tanggal $removedDate telah dibatalkan karena penutupan lapangan. Mohon maaf atas ketidaknyamananya',
            username,
          );
        }

        final timeSlotRef = firestore
            .collection('time_slots')
            .doc('${courtNumber}_$dateStr');
        batch.set(timeSlotRef, {'slots': slots}, SetOptions(merge: true));
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

      for (var doc in existingSlots.docs) {
        List<Map<String, dynamic>> updatedSlots = [];
        final slots = doc.data()['slots'] as List<dynamic>;

        Map<String, double> pointDeduction = {};
        Map<String, double> totalHourDeduction = {};
        Map<String, double> totalBookingDeduction = {};
        Map<String, List<String>> removedBookingDates = {};

        var beforeUserId = "";
        for (var slot in slots) {
          var updatedSlot = Map<String, dynamic>.from(slot);
          String userId = updatedSlot['userId'] ?? "";
          if (updatedSlot['userId'] == "" ||
              updatedSlot['userId'] == null) {
            updatedSlot['isClosed'] = true;
            updatedSlot['isAvailable'] = false;
            updatedSlots.add(updatedSlot);
          } else {
            updatedSlot['isClosed'] = true;
            updatedSlot['isAvailable'] = false;

            pointDeduction[userId] = (pointDeduction[userId] ?? 0) + 0.5;
            totalHourDeduction[userId] =
                (totalHourDeduction[userId] ?? 0) + 0.5;
            removedBookingDates[userId] =
                (removedBookingDates[userId] ?? []) + [dateStr];

            if (beforeUserId != userId && userId.isNotEmpty) {
              totalBookingDeduction[userId] =
                  (totalBookingDeduction[userId] ?? 0) + 1;
            }

            beforeUserId = userId;

            updatedSlots.add(updatedSlot);
          }
        }

        for (var userId in pointDeduction.keys) {
          final username = await FirebaseGetUser().getUserDataById(
            userId,
            'username',
          );
          await FirebaseUpdateUser().updateUser(
            'point',
            username,
            FieldValue.increment(-pointDeduction[userId]!),
          );
          await FirebaseUpdateUser().updateUser(
            'totalHour',
            username,
            FieldValue.increment(-totalHourDeduction[userId]!),
          );
          await FirebaseUpdateUser().updateUser(
            'totalBooking',
            username,
            FieldValue.increment(-totalBookingDeduction[userId]!),
          );

          List<String> bookingDates = List<String>.from(await FirebaseGetUser().getUserData(username, 'bookingDates') ?? []);
          String removedDate = removedBookingDates[userId]!.first;
          bookingDates.remove(removedDate);
          
          await FirebaseUpdateUser().updateUser(
            'bookingDates',
            username,
            bookingDates,
          );

          await OnesignalSendNotificationCustomers().sendNotification(
            "Perubahan Jadwal",
            'Booking Anda pada tanggal $removedDate telah dibatalkan karena penutupan lapangan. Mohon maaf atas ketidaknyamananya',
            username,
          );
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
