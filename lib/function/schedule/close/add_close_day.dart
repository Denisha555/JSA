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

      if (isDateInitialized.docs.length != courts.docs.length) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);
      }

      final startMins = timeToMinutes(startTime);
      final endMins = timeToMinutes(endTime);

      for (final court in courts.docs) {
        final courtNumber = court['nomor'];
        final docId = '${courtNumber}_$dateStr';

        final doc = await firestore.collection('time_slots').doc(docId).get();
        final slots = doc.data()!['slots'] as List<dynamic>;

        List<String> userList = [];

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
            userList.add(userId);
          }
          slots[slotIndex]['isClosed'] = true;
          slots[slotIndex]['isAvailable'] = false;
          slots[slotIndex]['userId'] = "";
          slots[slotIndex]['type'] = "";
        }

        for (var userId in userList) {
          final username = await FirebaseGetUser().getUserDataById(
            userId,
            'username',
          );

          List<dynamic> bookingDates = List<dynamic>.from(
            await FirebaseGetUser().getUserData(username, 'bookingDates') ?? [],
          );
          bookingDates.removeWhere(
            (data) =>
                data["date"] == dateStr &&
                timeToMinutes(data["startTime"]).toInt() >= startMins &&
                timeToMinutes(data["endTime"]).toInt() <= endMins,
          );

          if (bookingDates.isNotEmpty) {
            for (var data in bookingDates) {
              if (data["date"] == dateStr) {
                if (timeToMinutes(data["startTime"]).toInt() < startMins) {
                  if (timeToMinutes(data["endTime"]).toInt() > startMins) {
                    data["endTime"] = minutesToFormattedTime(startMins);
                  }
                }
                if (timeToMinutes(data["endTime"]).toInt() > endMins) {
                  if (timeToMinutes(data["startTime"]).toInt() < endMins) {
                    data["startTime"] = minutesToFormattedTime(endMins);
                  }
                }
              }
            }
          }

          await FirebaseUpdateUser().updateUser(
            'bookingDates',
            username,
            bookingDates,
          );

          await OnesignalSendNotificationCustomers().sendNotification(
            "Perubahan Jadwal",
            'Booking Anda pada tanggal ${formatDate(DateTime.parse(dateStr))} telah dibatalkan karena operasioanl JSA ditutup. Mohon maaf atas ketidaknyamananya',
            username,
          );
        }

        final timeSlotRef = firestore
            .collection('time_slots')
            .doc('${courtNumber}_$dateStr');
        batch.set(timeSlotRef, {'slots': slots}, SetOptions(merge: true));
      }

      await OnesignalSendNotificationCustomers().sendNotificationToAll(
        "Perubahan Jadwal",
        "Terjadi perubahan jadwal pada tanggal ${formatDate(selectedDate)}. Silakan cek kembali jadwal booking Anda.",
      );

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
      print("Failde to close range: ${e.toString()}");
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

        List<String> userList = [];

        for (var slot in slots) {
          var updatedSlot = Map<String, dynamic>.from(slot);
          String userId = updatedSlot['userId'] ?? "";
          if (updatedSlot['userId'] == "" || updatedSlot['userId'] == null) {
            updatedSlot['isClosed'] = true;
            updatedSlot['isAvailable'] = false;
            updatedSlots.add(updatedSlot);
          } else {
            updatedSlot['isClosed'] = true;
            updatedSlot['isAvailable'] = false;
            updatedSlot['userId'] = "";
            updatedSlot['type'] = "";
          
          if (updatedSlot['isHoliday'] == true ) {
            updatedSlot['isHoliday'] = false;
          }

            userList.add(userId);

            updatedSlots.add(updatedSlot);
          }
        }

        for (var userId in userList) {
          final username = await FirebaseGetUser().getUserDataById(
            userId,
            'username',
          );

          List<dynamic> bookingDates = List<dynamic>.from(
            await FirebaseGetUser().getUserData(username, 'bookingDates') ?? [],
          );
          bookingDates.removeWhere((data) => data["date"] == dateStr);

          await FirebaseUpdateUser().updateUser(
            'bookingDates',
            username,
            bookingDates,
          );

          await OnesignalSendNotificationCustomers().sendNotification(
            "Perubahan Jadwal",
            'Booking Anda pada tanggal ${formatDate(DateTime.parse(dateStr))} telah dibatalkan karena operasional JSA ditutup. Mohon maaf atas ketidaknyamananya',
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
      print('Failed to close all day: $e');
      throw Exception('Failed to close all day: $e');
    }
  }
}
