import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class CancelMember {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> cancelBooking(
    String username,
    String dateStr,
    String courtId,
    String startTime,
    String endTime,
  ) async {
    final batch = firestore.batch();
    final docId = '${courtId}_$dateStr';
    final doc = await firestore.collection('time_slots').doc(docId).get();

    try {
      final userQuery =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('user not found');
      }

      if (!doc.exists) {
        throw Exception('slot not found');
      }

      print('start time : $startTime');

      final slots = doc.data()!['slots'] as List<dynamic>;
      final slotIndex = slots.indexWhere(
        (slot) => slot['startTime'] == startTime,
      );

      await FirebaseCheckUser().checkMembership(username);

      var updatedSlot = List<Map<String, dynamic>>.from(slots);

      List<String> cancelList = List<String>.from(
        updatedSlot[slotIndex]['cancel'] ?? [],
      );

      QuerySnapshot user =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      String userId = user.docs[0].id;

      cancelList.add(userId);

      updatedSlot[slotIndex]['isAvailable'] = true;
      updatedSlot[slotIndex]['userId'] = '';
      updatedSlot[slotIndex]['type'] = '';
      updatedSlot[slotIndex]['cancel'] = cancelList;

      batch.set(firestore.collection('time_slots').doc(docId), {
        'slots': updatedSlot,
      }, SetOptions(merge: true));

      batch.commit();
    } catch (e) {
      throw 'Error canceling booking: $e';
    }
  }

  Future<void> updateUserCancel(
    String username,
    String dateStr,
    String startTime,
    String endTime,
    String court,
  ) async {
    try {
      final docRef =
          await firestore
              .collection('users')
              .where("username", isEqualTo: username)
              .get();

      final docId = docRef.docs.first.id;

      if (docRef.docs.isNotEmpty) {
        final data = docRef.docs.first.data();
        final List<Map<String, dynamic>> currentDates =
            data['bookingDates'] != null
                ? (data['bookingDates'] as List<dynamic>)
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : [];

        currentDates.sort((a, b) {
          final dateCompare = a['date'].toString().compareTo(
            b['date'].toString(),
          );
          
          if (dateCompare != 0) return dateCompare;

          final courtCompare = a['courtId'].toString().compareTo(
            b['courtId'].toString(),
          );  

          if (courtCompare != 0) return courtCompare;

          return timeToMinutes(
            a['startTime'],
          ).compareTo(timeToMinutes(b['startTime']));
        });

        for (int i = 0; i < currentDates.length - 1; i++) {
          final curr = currentDates[i];
          final next = currentDates[i + 1];

          final sameCourt = curr['courtId'] == next['courtId'];
          final sameDate = curr['date'] == next['date'];

          final currEnd = curr['endTime'];
          final nextStart = next['startTime'];

          final isConnected = currEnd == nextStart;

          if (sameCourt && sameDate && isConnected) {
            currentDates.removeAt(i + 1);
            curr['endTime'] = next['endTime'];
            i--;
          }
        }

        final List<Map<String, dynamic>> cancelDates =
            data['cancelDate'] != null
                ? (data['cancelDate'] as List<dynamic>)
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : [];

        List<Map<String, dynamic>> updatedDates =
            List<Map<String, dynamic>>.from(currentDates);
        updatedDates.removeWhere(
          (d) =>
              d['date'] == dateStr &&
              d['startTime'] == startTime &&
              d['endTime'] == endTime &&
              d['courtId'] == court,
        );

        List<Map<String, dynamic>> updatedCancelDates =
            List<Map<String, dynamic>>.from(cancelDates);
        final temp = {
          'date': dateStr,
          'startTime': startTime,
          'endTime': endTime,
          'courtId': court,
          'type': "member",
        };

        updatedCancelDates.add(temp);

        await firestore.collection('users').doc(docId).set({
          'cancel': FieldValue.increment(1),
          'cancelDate': updatedCancelDates,
          'bookingDates': updatedDates,
          'memberCurrentTotalBooking': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Error updating user cancel: $e');
    }
  }
}
