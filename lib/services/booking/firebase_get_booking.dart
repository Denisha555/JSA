import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';


class FirebaseGetBooking {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<TimeSlotModel>> getBookingByUsername(
    String username, {
    DateTime? selectedDate,
  }) async {
    try {
      QuerySnapshot userSnapshot =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;

      // Ambil daftar tanggal cancel dari field 'bookingDates'
      final bookingDates = userData['bookingDates'];

      print('Booking dates for $username: $bookingDates');

      // Kalau tidak ada bookingDates, return list kosong
      if (bookingDates == null || bookingDates.isEmpty) {
        return [];
      }

      List<TimeSlotModel> allSlots = [];

      for (var date in bookingDates) {
        final timeSlots = await firestore
            .collection('time_slots')
            .where('date', isEqualTo: date)
            .get();

        for (var doc in timeSlots.docs) {
          final slots = doc.data()['slots'] as List<dynamic>;
          for (var slot in slots) {
            if (slot['username'] == username) {
              allSlots.add(TimeSlotModel.fromJson(slot, date: date, courtId: doc.id.split('_')[0]));
              print('Found slot for $username on $date: ${slot['startTime']} - ${slot['endTime']}');
              print('Court ID: ${doc.id.split('_')[0]}');
            }
          }
        }
      }
      print(allSlots[0].date);
      return allSlots;
    } catch (e) {
      throw Exception('Failed to get time slots for $username: $e');
    }
  }

  Future<List<TimeSlotModel>> getCancelBookingByUsername(
    String username,
  ) async {
    try {
      // Ambil dokumen user berdasarkan username
      QuerySnapshot userSnapshot =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;

      // Ambil daftar tanggal cancel dari field 'cancelDate'
      final cancelDate = userData['cancelDate'];

      // Kalau tidak ada cancelDate, return list kosong
      if (cancelDate == null || cancelDate.isEmpty) {
        return [];
      }

      List<TimeSlotModel> allSlots = [];

      // Loop semua tanggal cancel
      for (var date in cancelDate) {
        final timeSlots =
            await firestore
                .collection('time_slots')
                .where('date', isEqualTo: date)
                .get();

        for (var doc in timeSlots.docs) {
          final slots = doc.data()['slots'] as List<dynamic>;
          for (var slot in slots) {
            if (slot.cancel.contains(username)) {
              allSlots.add(slot);
            }
          }
        }
      }

      return allSlots;
    } catch (e) {
      throw Exception('Failed to get time slots for $username: $e');
    }
  }
}
