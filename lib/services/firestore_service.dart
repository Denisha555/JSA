import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimeSlot {
  final String courtId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isAvailable;

  TimeSlot({
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      courtId: json['courtId'],
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isAvailable: json['isAvailable'],
    );
  }
}

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Fungsi untuk menambahkan user ke Firestore
  Future<void> addUser(String userName, String password) async {
    try {
      CollectionReference users = firestore.collection('users');
      await users.add({'username': userName, 'password': password});
    } catch (e) {
      throw Exception('Error Adding User: $e');
    }
  }

  // Fungsi untuk mengecek apakah user ada di Firestore
  Future<bool> checkUser(String userName) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot =
          await users.where('username', isEqualTo: userName).get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  // Fungsi untuk mengecek apakah password user benar
  Future<bool> checkPassword(String userName, String password) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot =
          await users
              .where('username', isEqualTo: userName)
              .where('password', isEqualTo: password)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  // Fungsi untuk menyimpan gambar promo dan event ke Firestore
  Future<void> savePromoEventImage(String imageUrl) async {
    try {
      CollectionReference promoevent = firestore.collection('promoevent');
      await promoevent.add({'image': imageUrl});
    } catch (e) {
      throw Exception('Error Saving Image: $e');
    }
  }

  // Fungsi untuk menghapus gambar promo dan event di Firestore
  Future<void> deletePromoEventImage(String imageUrl) async {
    try {
      CollectionReference promoevent = firestore.collection('promoevent');
      QuerySnapshot querySnapshot =
          await promoevent.where('image', isEqualTo: imageUrl).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        await documentSnapshot.reference.delete();
      }
    } catch (e) {
      throw Exception('Error Deleting Image: $e');
    }
  }

  // Fungsi untuk menyimpan harga ke Firestore
  Future<void> saveHarga(
    String type,
    int jamMulai,
    int jamSelesai,
    String hariMulai,
    String hariSelesai,
    int harga,
  ) async {
    try {
      CollectionReference hargaCollection = firestore.collection('harga');
      await hargaCollection.add({
        'type': type,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'hari_mulai': hariMulai,
        'hari_selesai': hariSelesai,
        'harga': harga,
      });
    } catch (e) {
      throw Exception('Error Saving Harga: $e');
    }
  }

  // Fungsi untuk cek data harga di Firestore
  Future<bool> checkHarga(
    String type,
    int jamMulai,
    int jamSelesai,
    String hariMulai,
    String hariSelesai,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await firestore
              .collection('harga')
              .where('type', isEqualTo: type)
              .where('jam_mulai', isEqualTo: jamMulai)
              .where('jam_selesai', isEqualTo: jamSelesai)
              .where('hari_mulai', isEqualTo: hariMulai)
              .where('hari_selesai', isEqualTo: hariSelesai)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error Checking Harga: $e');
    }
  }

  // Fungsi untuk mendapatkan ID dokumen dari harga
  Future<String?> getHargaDocumentId(
    String type,
    int jamMulai,
    int jamSelesai,
    String hariMulai,
    String hariSelesai,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await firestore
              .collection('harga')
              .where('type', isEqualTo: type)
              .where('jam_mulai', isEqualTo: jamMulai)
              .where('jam_selesai', isEqualTo: jamSelesai)
              .where('hari_mulai', isEqualTo: hariMulai)
              .where('hari_selesai', isEqualTo: hariSelesai)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      throw Exception('Error Getting Harga Document ID: $e');
    }
  }

  // Fungsi untuk menambahkan lapangan ke Firestore
  Future<void> tambahLapangan({
    required String nomor,
    required String deskripsi,
    String? imageUrl,
  }) async {
    try {
      CollectionReference lapanganCollection = firestore.collection('lapangan');
      await lapanganCollection.add({
        'nomor': nomor,
        'deskripsi': deskripsi,
        'image': imageUrl,
      });
    } catch (e) {
      throw Exception('Error menambahkan lapangan: $e');
    }
  }

  // Fungsi untuk update lapangan di Firestore
  Future<void> updateLapangan({
    required String documentId,
    required String nomor,
    Timestamp? createdAt,
    String? deskripsi,
    String? imageUrl,
  }) async {
    try {
      CollectionReference lapanganCollection = firestore.collection('lapangan');
      await lapanganCollection.doc(documentId).update({
        'nomor': nomor,
        'deskripsi': deskripsi,
        'image': imageUrl,
      });
    } catch (e) {
      throw Exception('Error mengupdate lapangan: $e');
    }
  }

  // Fungsi untuk mengecek apakah lapangan sudah ada di Firestore
  Future<bool> checkLapangan(String nomor) async {
    try {
      QuerySnapshot querySnapshot =
          await firestore
              .collection('lapangan')
              .where('nomor', isEqualTo: nomor)
              .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error Checking Lapangan: $e');
    }
  }

  // Fungsi untuk menghapus lapangan di Firestore
  Future<void> hapusLapangan(String docId) async {
    try {
      CollectionReference lapanganCollection = firestore.collection('lapangan');
      await lapanganCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('Error menghapus lapangan: $e');
    }
  }

  // Fungsi untuk menambahkan promo dan event ke Firestore
  Future<void> tambahPromoEvent({required String imageurl}) async {
    try {
      CollectionReference promoEventCollection = firestore.collection(
        'promo_event',
      );
      await promoEventCollection.add({'gambar': imageurl});
    } catch (e) {
      throw Exception('Failed to create promo event: $e');
    }
  }

  Future<void> deletePromoEvent(String id) async {
    try {
      CollectionReference promoEventCollection = firestore.collection(
        'promo_event',
      );
      await promoEventCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete promo event: $e');
    }
  }

  // Fungsi untuk mengenerate slot 7 hari
  Future<void> generateSlots7day() async {
    try {
      final courts = await firestore.collection('lapangan').get();
      final today = DateTime.now();

      for (var i = 0; i < 7; i++) {
        final targetDate = DateTime(today.year, today.month, today.day + i);
        final dateStr =
            "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

        for (var court in courts.docs) {
          final courtNumber = court.data()['nomor'].toString();

          // Cek apakah slot untuk tanggal dan lapangan ini sudah ada
          final existing =
              await firestore
                  .collection('time_slots')
                  .where('courtId', isEqualTo: courtNumber)
                  .where('date', isEqualTo: dateStr)
                  .limit(1)
                  .get();

          if (existing.docs.isEmpty) {
            for (int hour = 7; hour <= 22; hour++) {
              for (int minute = 0; minute < 60; minute += 30) {
                final startTime =
                    "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
                final endTime = DateTime(
                  targetDate.year,
                  targetDate.month,
                  targetDate.day,
                  hour,
                  minute,
                ).add(Duration(minutes: 30));
                final endTimeStr =
                    "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
                final slotId =
                    "${courtNumber}_${dateStr}_${startTime.replaceAll(':', '')}";

                await firestore.collection('time_slots').doc(slotId).set({
                  'courtId': courtNumber,
                  'date': dateStr,
                  'startTime': startTime,
                  'endTime': endTimeStr,
                  'isAvailable': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to generate slots: $e');
    }
  }

  // Fungsi untuk mengenerate slot hari ini
  Future<void> generateSlotsToday() async {
    try {
      final courts = await firestore.collection('lapangan').get();
      final today = DateTime.now();

      final targetDate = DateTime(today.year, today.month, today.day);
      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      for (var court in courts.docs) {
        final courtNumber = court.data()['nomor'].toString();

        // Cek apakah slot untuk tanggal dan lapangan ini sudah ada
        final existing =
            await firestore
                .collection('time_slots')
                .where('courtId', isEqualTo: courtNumber)
                .where('date', isEqualTo: dateStr)
                .limit(1)
                .get();

        if (existing.docs.isEmpty) {
          for (int hour = 7; hour <= 22; hour++) {
            for (int minute = 0; minute < 60; minute += 30) {
              final startTime =
                  "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
              final endTime = DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                hour,
                minute,
              ).add(Duration(minutes: 30));
              final endTimeStr =
                  "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
              final slotId =
                  "${courtNumber}_${dateStr}_${startTime.replaceAll(':', '')}";

              await firestore.collection('time_slots').doc(slotId).set({
                'courtId': courtNumber,
                'date': dateStr,
                'startTime': startTime,
                'endTime': endTimeStr,
                'isAvailable': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to generate slots: $e');
    }
  }

  // Fungsi mengenerate slot satu hari
  Future<void> generateSlotsOneDay(DateTime selectedDate) async {
    try {
      final courts = await firestore.collection('lapangan').get();

      final targetDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      for (var court in courts.docs) {
        final courtNumber = court.data()['nomor'].toString();

        // Cek apakah slot untuk tanggal dan lapangan ini sudah ada
        final existing =
            await firestore
                .collection('time_slots')
                .where('courtId', isEqualTo: courtNumber)
                .where('date', isEqualTo: dateStr)
                .limit(1)
                .get();

        if (existing.docs.isEmpty) {
          for (int hour = 7; hour <= 22; hour++) {
            for (int minute = 0; minute < 60; minute += 30) {
              final startTime =
                  "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
              final endTime = DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                hour,
                minute,
              ).add(Duration(minutes: 30));
              final endTimeStr =
                  "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
              final slotId =
                  "${courtNumber}_${dateStr}_${startTime.replaceAll(':', '')}";

              await firestore.collection('time_slots').doc(slotId).set({
                'courtId': courtNumber,
                'date': dateStr,
                'startTime': startTime,
                'endTime': endTimeStr,
                'isAvailable': true,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to generate slots: $e');
    }
  }

  // Fungsi untuk mengambil data slot dari Firestore
  Future<List<TimeSlot>> getTimeSlotsByDate(String dateStr) async {
    try {
      
      final QuerySnapshot querySnapshot =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .get();

      return querySnapshot.docs.map((doc) {
        return TimeSlot.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get time slots: $e');
    }
  }

  // Fungsi untuk mengambil data slot dari Firestore
  Future<List<TimeSlot>> getTimeSlotsByTime(String startTime, String courts, DateTime selectedDate) async {
    try {
      final targetDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final dateStr =
            "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      final QuerySnapshot querySnapshot =
          await firestore
            .collection('time_slots')
            .where('date', isEqualTo: dateStr)
            .where('courtId', isEqualTo: courts)
            .where('startTime', isEqualTo: startTime)
            .get();

      return querySnapshot.docs.map((doc) {
        return TimeSlot.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get time slots: $e');
    }
  }

  // Fungsi untuk mengecek ketersediaan slot berdasarkan id dan lapangan
  Future<bool> isSlotAvailable(String startTime, String courts, DateTime selectedDate) async {
    try {
      final targetDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        final dateStr =
            "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      final QuerySnapshot slotSnapshot =
          await firestore
            .collection('time_slots')
            .where('date', isEqualTo: dateStr)
            .where('courtId', isEqualTo: courts)
            .where('startTime', isEqualTo: startTime)
            .get();
      if (slotSnapshot.docs.isNotEmpty) {
        final TimeSlot slot = TimeSlot.fromJson(
          slotSnapshot.docs.first.data() as Map<String, dynamic>);
      return slot.isAvailable;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Failed to check slot availability: $e');
    }
  }

  // Fungsi untuk booking slot
  Future<void> bookSlot(String slotId, String username) async {
    try {
      await firestore.collection('time_slots').doc(slotId).update({
        'isAvailable': false,
        'username': username,
      });
    } catch (e) {
      throw Exception('Failed to book slot: $e');
    }
  }
}
