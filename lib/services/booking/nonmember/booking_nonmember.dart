import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
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
    try {
      final docRef =
          await firestore
              .collection('users')
              .where("username", isEqualTo: username)
              .get();

      final docId = docRef.docs.first.id;
      if (docRef.docs.isNotEmpty) {
        final data = docRef.docs.first.data();

        List<Map<String, dynamic>> currentDates =
            data['bookingDates'] != null
                ? (data['bookingDates'] as List<dynamic>)
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : [];

        final temp = {
          "date": dates[0],
          "courtId": court,
          "startTime": startTime,
          "endTime": endTime,
          "id": '${court}_${dates[0]}',
          "type": "nonMember",
          "status": "",
        };

        currentDates.add(temp);

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
          final sameType = curr['type'] == next['type'];

          final currEnd = curr['endTime'];
          final nextStart = next['startTime'];

          final isConnected = currEnd == nextStart;

          if (sameCourt && sameDate && isConnected && sameType) {
            currentDates.removeAt(i + 1);
            curr['endTime'] = next['endTime'];
            i--;
          }
        }

        await firestore.collection('users').doc(docId).set({
          'bookingDates': currentDates,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Failed to add booking dates: $e");
      throw Exception('Failed to add booking dates: $e');
    }
  }
}
