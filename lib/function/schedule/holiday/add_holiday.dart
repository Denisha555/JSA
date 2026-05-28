import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/notification/onesignal_send_notification.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';

class AddHoliday {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addHoliday(DateTime selectedDate) async {
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

      // Kalau belum ada slot, tambahkan dulu
      if (existingSlots.docs.isEmpty) {
        await FirebaseAddTimeSlot().addTimeSlot(selectedDate);

        existingSlots =
            await firestore
                .collection('time_slots')
                .where('date', isEqualTo: dateStr)
                .get();
      }

      List<String> affectedUsers = [];

      for (var doc in existingSlots.docs) {
        final List<Map<String, dynamic>> updatedSlots = [];
        final slots = doc.data()['slots'] as List<dynamic>;
        for (var slot in slots) {
          var updatedSlot = Map<String, dynamic>.from(slot);
          updatedSlot['isHoliday'] = true;
          updatedSlots.add(updatedSlot);
          if (updatedSlot['userId'] != "" && updatedSlot['userId'] != null) {
            affectedUsers.add(updatedSlot['userId']);
          }
        }
        doc.reference.set({'slots': updatedSlots}, SetOptions(merge: true));
      }

      for (var userId in affectedUsers.toSet()) {
        final username = await FirebaseGetUser().getUserDataById(userId, 'username');
        await OnesignalSendNotificationCustomers().sendNotification(
          "Perubahan Jadwal",
          'Terjadi perubahan jadwal booking Anda pada tanggal ${formatDate(DateTime.parse(dateStr))} karena hari libur. Mohon cek kembali jadwal booking Anda.',
          username,
        );
      }

      // Tambahkan catatan ke koleksi jadwal_khusus
      await firestore.collection('jadwal_khusus').add({
        'date': dateStr,
        'startTime': '07:00',
        'endTime': '23:00',
        'type': 'holiday',
      });
    } catch (e) {
      throw Exception('Failed to add holiday: $e');
    }
  }
}
