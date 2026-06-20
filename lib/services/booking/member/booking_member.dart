import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class BookingMember {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> bookSlotForMember(
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
          updatedSlot[i]['type'] = 'member';
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
      throw Exception('Failed to book slot for member: $e');
    }
  }

  // digunakan saat mendaftar sebagai member
  Future<void> addTotalBookingDays(
    String username,
    int days,
    int length,
  ) async {
    try {
      print('add total booking days');
      print(length);
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

        String userId = user.docs[0].id;
        await firestore.collection('users').doc(userId).set({
          'memberTotalBooking': FieldValue.increment(days),
          'memberCurrentTotalBooking': FieldValue.increment(days),
          'memberBookingLength': FieldValue.increment(length),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to add total days: $e');
    }
  }

  Future<void> addBookingDates(
    String username,
    dynamic dates,
    dynamic courtId,
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

        List<Map<String, dynamic>> temp = [];

        for (var date in dates) {
          for (var court in courtId) {
            final data = {
              "date": date,
              "courtId": court,
              "startTime": startTime,
              "endTime": endTime,
              "id": '${court}_$date',
              "type": "member",
              "status": "",
            };
            temp.add(data);
          }
        }

        currentDates.addAll(temp);

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

        await firestore.collection('users').doc(docId).set({
          'bookingDates': currentDates,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to add booking dates: $e');
    }
  }

  // digunakan saat melakukan booking ulang di kalender
  Future<void> addTotalBooking(String username) async {
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
        String userId = user.docs[0].id;
        await firestore.collection('users').doc(userId).set({
          'memberCurrentTotalBooking': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to add total booking: $e');
    }
  }
}
