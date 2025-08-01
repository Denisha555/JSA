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

  // Future<List<CourtModel>> getAllLapanganToday() async {
  //   try {
  //     DateTime now = DateTime.now();
  //     String formattedDate = DateFormat('yyyy-MM-dd').format(now);

  //     // Cek apakah sudah ada slot hari ini
  //     final existingSlots =
  //         await firestore
  //             .collection('time_slots')
  //             .where('date', isEqualTo: formattedDate)
  //             .get();

  //     if (existingSlots.docs.isEmpty) {
  //       await FirebaseAddTimeSlot().addTimeSlot(now); 
  //     }

  //     // Ambil semua lapangan
  //     QuerySnapshot courtsSnapshot =
  //         await firestore.collection('lapangan').get();

  //     List<CourtModel> courtsToday = [];

  //     for (var doc in courtsSnapshot.docs) {
  //       final courtId = doc.get('nomor').toString();

  //       final slotSnapshot =
  //           await firestore
  //               .collection('time_slots')
  //               .where('date', isEqualTo: formattedDate)
  //               .where('courtId', isEqualTo: courtId)
  //               .where('isAvailable', isEqualTo: true)
  //               .get();

  //       final filteredSlots =
  //           slotSnapshot.docs.where((doc) {
  //             final startTimeStr = doc.get('startTime') as String;

  //             final parts = startTimeStr.split(':');
  //             if (parts.length != 2) return false;

  //             final slotTime = TimeOfDay(
  //               hour: int.parse(parts[0]),
  //               minute: int.parse(parts[1]),
  //             );

  //             // Ambil field isClosed, kalau tidak ada anggap false
  //             final isClosed =
  //                 doc.data().containsKey('isClosed')
  //                     ? doc.get('isClosed') as bool
  //                     : false;

  //             final currentTime = TimeOfDay.fromDateTime(DateTime.now());

  //             return !isClosed &&
  //                 (slotTime.hour > currentTime.hour ||
  //                     (slotTime.hour == currentTime.hour &&
  //                         slotTime.minute > currentTime.minute));
  //           }).toList();

  //       if (filteredSlots.isNotEmpty) {
  //         courtsToday.add(
  //           CourtModel.fromJson({
  //             'nomor': courtId,
  //             'imageUrl': doc.get('image') ?? '',
  //           }),
  //         );
  //       }
  //     }

  //     return courtsToday;
  //   } catch (e) {
  //     throw Exception('Error checking lapangan: $e');
  //   }
  // }

  Future<List<CourtModel>> getAllLapanganToday() async {
  try {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);

    // 1. Cek apakah slot hari ini sudah dibuat
    final existingSlots = await firestore
        .collection('time_slots')
        .where('date', isEqualTo: formattedDate)
        .get();

    if (existingSlots.docs.isEmpty) {
      await FirebaseAddTimeSlot().addTimeSlot(now);
    }

    // 2. Ambil semua lapangan
    final courtsSnapshot = await firestore.collection('lapangan').get();
    List<CourtModel> courtsToday = [];

    for (var courtDoc in courtsSnapshot.docs) {
      final courtId = courtDoc.get('nomor').toString();

      // Ambil slot dari lapangan tertentu
      final slotSnapshot = await firestore
          .collection('time_slots')
          .where('date', isEqualTo: formattedDate)
          .where('courtId', isEqualTo: courtId)
          .get();

      bool hasAvailableSlot = false;
      final currentTime = TimeOfDay.fromDateTime(now);

      for (var slotDoc in slotSnapshot.docs) {
        final slots = slotDoc.data()['slots'] as List<dynamic>;

        for (var slot in slots) {
          if (slot['isAvailable'] == true && slot['isClosed'] != true) {
            final startTime = slot['startTime'] as String;
            final parts = startTime.split(':');

            if (parts.length == 2) {
              final slotTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );

              // Bandingkan dengan waktu sekarang
              final isUpcoming = slotTime.hour > currentTime.hour ||
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