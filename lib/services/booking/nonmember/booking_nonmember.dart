import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class BookingNonMember {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> bookSlotForNonMember(
    String courtId,
    String dateStr,
    String startTime,
    String endTime,
    String username,
  ) async {
    try {
      final docId = '${courtId}_$dateStr';
      final doc = await firestore.collection('time_slots').doc(docId).get();

      QuerySnapshot user =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      String userId = user.docs[0].id;

      if (!doc.exists) {
        throw Exception('Slot not found');
      }

      final slots = doc.data()!['slots'] as List<dynamic>;
      var updatedSlot = List<Map<String, dynamic>>.from(slots);
      bool inRange = false;

      for (int i = 0; i < updatedSlot.length; i++) {
        final slot = updatedSlot[i];

        if (slot['startTime'] == startTime) {
          inRange = true;
        }

        if (inRange) {
          if (slot['isAvailable'] != true) {
            throw Exception('Ada slot yang sudah dibooking');
          }

          updatedSlot[i]['isAvailable'] = false;
          updatedSlot[i]['type'] = 'nonMember';
          updatedSlot[i]['userId'] = userId;
        }

        if (slot['endTime'] == endTime && inRange) {
          break;
        }
      }

      await firestore.collection('time_slots').doc(docId).update({
        'slots': updatedSlot,
      });
    } catch (e) {
      throw Exception('Failed to book slots for non-member: $e');
    }
  }

  Future<void> addTotalHour(String username) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );
      if (exist) {
        QuerySnapshot user =
            await firestore
                .collection('users')
                .where('username', isEqualTo: username)
                .get();

        await firestore.collection('users').doc(user.docs[0].id).set({
          'totalHour': FieldValue.increment(0.5),
          'point': FieldValue.increment(0.5),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to add total booking: $e');
    }
  }

  Future<void> addBookingDates(
    String username,
    List<String> dates,
    String court,
    String startTime,
    String endTime,
  ) async {
    QuerySnapshot user =
        await firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .get();

    final userDoc = firestore.collection('users').doc(user.docs[0].id);

    final snapshot = await userDoc.get();
    List<Map<String, dynamic>> currentDates = [];

    if (snapshot.exists && snapshot.data()!.containsKey('bookingDates')) {
      final data = snapshot.data()!['bookingDates'];

      if (data is List) {
        currentDates = List<Map<String, dynamic>>.from(data);
      }
    }

    final bookingInfo = {
      "date": dates[0],
      "court": court,
      "startTime": startTime,
      "endTime": endTime,
      "id": '${court}_${dates[0]}',
      "type": "nonMember",
      "status": "",
    };

    currentDates.add(bookingInfo);

    await userDoc.set({'bookingDates': currentDates}, SetOptions(merge: true));
  }
}
