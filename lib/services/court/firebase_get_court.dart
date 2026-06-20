import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/court_model.dart';
import 'package:flutter_application_1/services/time_slot/firebase_add_time_slot.dart';

class FirebaseGetCourt {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<CourtModel>> getCourts() async {
    try {
      List<CourtModel> courtList = [];

      QuerySnapshot querySnapshot =
          await firestore.collection('lapangan').get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        courtList.add(CourtModel.fromJson(doc.data() as Map<String, dynamic>));
      }
      return courtList;
    } catch (e) {
      throw Exception('Error Getting court: $e');
    }
  }

  Future<List<CourtModel>> getAllLapanganToday() async {
    try {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd').format(now);

      // 1. Cek apakah slot hari ini sudah dibuat
      final results = await Future.wait([
        firestore
            .collection('time_slots')
            .where('date', isEqualTo: formattedDate)
            .get(),

        firestore.collection('lapangan').get(),
      ]);

      final existingSlots = results[0].docs;
      final courtsSnapshot = results[1].docs;

      List<CourtModel> courtsToday = [];

      if (existingSlots.isEmpty) {
        await FirebaseAddTimeSlot().addTimeSlot(now);
        for (var courtDoc in courtsSnapshot) {
          final courtId = courtDoc.get('nomor').toString();
          courtsToday.add(
            CourtModel.fromJson({
              'nomor': courtId,
              'imageUrl': courtDoc.get('image') ?? '',
            }),
          );
        }
        courtsToday.sort((a, b) => a.courtId.compareTo(b.courtId));
        return courtsToday;
      }

      Map<String, List<QueryDocumentSnapshot>> courtSlots = {};
      for (var slotDoc in existingSlots) {
        final courtId =
            slotDoc.get('courtId').toString(); 
        courtSlots.putIfAbsent(courtId, () => []).add(slotDoc);
      }

      for (var courtDoc in courtsSnapshot) {
        final courtId = courtDoc.get('nomor').toString();

        final slotDocs = courtSlots[courtId] ?? [];

        bool hasAvailableSlot = false;
        final currentTime = TimeOfDay.fromDateTime(now);

        for (var slotDoc in slotDocs) {
          final slots = slotDoc['slots'] as List<dynamic>;

          for (var slot in slots) {
            if (slot['isAvailable'] == true && slot['isClosed'] == false) {
              final startTime = slot['startTime'] as String;
              final parts = startTime.split(':');

              if (parts.length == 2) {
                final slotTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );

                final isUpcoming =
                    slotTime.hour > currentTime.hour ||
                    (slotTime.hour == currentTime.hour &&
                        slotTime.minute > currentTime.minute);

                if (isUpcoming) {
                  hasAvailableSlot = true;
                  break;
                }
              }
            }
          }

          if (hasAvailableSlot) break;
        }

        if (hasAvailableSlot) {
          courtsToday.add(
            CourtModel.fromJson({
              'nomor': courtId,
              'imageUrl': courtDoc.get('image') ?? '',
            }),
          );
        }
      }
      courtsToday.sort((a, b) => a.courtId.compareTo(b.courtId));
      return courtsToday;
    } catch (e) {
      throw Exception('Error checking lapangan: $e');
    }
  }
}
