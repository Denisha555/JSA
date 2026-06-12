import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/notification/onesignal_send_notification.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';

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
      
      List<String> affectedUsers = [];

      if (docId.docs.isEmpty) {
        throw Exception('No time slots found for the selected date.');
      } else {
        
        
        for (var doc in docId.docs) {
          List<dynamic> slots = doc.data()['slots'];
          List<Map<String, dynamic>> updatedSlots = [];
          for (var slot in slots) {
            var updatedSlot = Map<String, dynamic>.from(slot);
            updatedSlot['isHoliday'] = false;
            updatedSlots.add(updatedSlot);
            if (updatedSlot['userId'] != "" && updatedSlot['userId'] != null) {
              affectedUsers.add(updatedSlot['userId']);
            }
          }
          doc.reference.set({'slots': updatedSlots}, SetOptions(merge: true));
        }
      }

      for (var userId in affectedUsers.toSet()) {
        final username = await FirebaseGetUser().getUserDataById(userId, 'username');
        await OnesignalSendNotificationCustomers().sendNotification(
          "Perubahan Jadwal",
          'Terjadi perubahan jadwal booking Anda pada tanggal ${formatDate(DateTime.parse(selectedDate))}. Mohon cek kembali jadwal booking Anda.',
          username,
        );
      }

      await OnesignalSendNotificationCustomers().sendNotificationToAll(
        "Perubahan Jadwal",
        'Terjadi perubahan jadwal pada tanggal ${formatDate(DateTime.parse(selectedDate))}. Mohon cek kembali jadwal booking Anda.',
      );
    } catch (e) {
      throw Exception('Failed to delete holiday: $e');
    }
  }
}
