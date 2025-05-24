import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TimeSlot {
  final String courtId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final bool isClosed;

  TimeSlot({
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.isClosed,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      courtId: json['courtId'],
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isAvailable: json['isAvailable'],
      isClosed: json['isClosed'] ?? false,
    );
  }
}

class TimeSlotForAdmin {
  final String courtId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final bool isClosed;
  final String? username;

  TimeSlotForAdmin({
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.isClosed,
    required this.username,
  });

  factory TimeSlotForAdmin.fromJson(Map<String, dynamic> json) {
    return TimeSlotForAdmin(
      courtId: json['courtId'],
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isAvailable: json['isAvailable'],
      isClosed: json['isClosed'] ?? false,
      username: json['username'] ?? "",
    );
  }
}

class AllBookedUser {
  final String courtId;
  final String date;
  final String startTime;
  final String endTime;
  final String username;

  AllBookedUser({
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.username,
  });

  factory AllBookedUser.fromJson(Map<String, dynamic> json) {
    return AllBookedUser(
      courtId: json['courtId'],
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      username: json['username'],
    );
  }
}

class AllUser {
  final String username;
  final String role;

  AllUser({required this.username, required this.role});

  factory AllUser.fromJson(Map<String, dynamic> json) {
    return AllUser(username: json['username'], role: json['role'] ?? '');
  }
}

class AvailableForMember {
  final String courtId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final bool isClosed;

  AvailableForMember({
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.isClosed,
  });

  factory AvailableForMember.fromJson(Map<String, dynamic> json) {
    return AvailableForMember(
      courtId: json['courtId'],
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isAvailable: json['isAvailable'],
      isClosed: json['isClosed'] ?? false,
    );
  }
}

class AllCourts {
  final String courtId;

  AllCourts({required this.courtId});

  factory AllCourts.fromJson(Map<String, dynamic> json) {
    return AllCourts(courtId: json['nomor']);
  }
}

class AllCloseDay {
  final String date;
  final String isClose;
  final String startTime;
  final String endTime;

  AllCloseDay({
    required this.date,
    required this.isClose,
    required this.startTime,
    required this.endTime,
  });

  factory AllCloseDay.fromJson(Map<String, dynamic> json) {
    return AllCloseDay(
      date: json['date'],
      isClose: json['isClosed'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}

class LastActivity {
  final String date;
  final String startTime;
  final String endTime;
  final String courtId;

  LastActivity({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.courtId,
  });

  factory LastActivity.fromJson(Map<String, dynamic> json) {
    return LastActivity(
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      courtId: json['courtId'],
    );
  }
}

class SlotStatus {
  final String startTime;
  final bool isAvailable;
  final bool isClosed;

  SlotStatus({
    required this.startTime,
    required this.isAvailable,
    required this.isClosed,
  });

  factory SlotStatus.fromJson(Map<String, dynamic> json) {
    return SlotStatus(
      startTime: json['startTime'],
      isAvailable: json['isAvailable'],
      isClosed: json['isClosed'] ?? false,
    );
  }
}

class UserData {
  final String username;
  final String startTime;
  final double point;
  final double totalHour;
  final int totalBooking;

  UserData({
    required this.username,
    required this.startTime,
    required this.point,
    required this.totalHour,
    required this.totalBooking,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      username: json['username'] ?? '',
      startTime: json['startTime'] ?? '',
      point: (json['point'] ?? 0).toDouble(),
      totalHour: (json['totalHours'] ?? 0).toDouble(),
      totalBooking: (json['totalBooking'] ?? 0).toInt(),
    );
  }
}

class UserProfil {
  final String username;
  final String name;
  final String club;
  final String phoneNumber;

  UserProfil({
    required this.username,
    required this.name,
    required this.club,
    required this.phoneNumber,
  });

  factory UserProfil.fromJson(Map<String, dynamic> json) {
    return UserProfil(
      username: json['username'],
      name: json['name'],
      club: json['club'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }
}

const _timeSlots = [
  '07:00',
  '07:30',
  '08:00',
  '08:30',
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '12:00',
  '12:30',
  '13:00',
  '13:30',
  '14:00',
  '14:30',
  '15:00',
  '15:30',
  '16:00',
  '16:30',
  '17:00',
  '17:30',
  '18:00',
  '18:30',
  '19:00',
  '19:30',
  '20:00',
  '20:30',
  '21:00',
  '21:30',
  '22:00',
  '22:30',
];

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final Map<String, List<TimeSlot>> _timeSlotCache = {};
  final Map<String, dynamic> _courtsCache = {};

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatMinutes(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '${hours}${mins}';
  }

  // Fungsi untuk menambahkan user ke Firestore
  Future<void> addUser(String userName, String password, String name, String club, String phoneNumber) async {
    try {
      CollectionReference users = firestore.collection('users');
      await users.add({'username': userName, 'password': password, 'name': name, 'club': club, 'phoneNumber': phoneNumber});
    } catch (e) {
      throw Exception('Error Adding User: $e');
    }
  }

  Future<void> addAdminOwner(String userName, String password) async {
    try {
      CollectionReference users = firestore.collection('users');
      await users.add({'username': userName, 'password': password});
    } catch (e) {
      throw Exception('Error Adding User: $e');
    }
  }


  // Fungsi untuk menambahkan user ke Firestore oleh admin

  Future<void> addUserByAdmin(String username) async {
    try {
      CollectionReference users = firestore.collection('users');
      if (username.length < 6) {
        await users.add({
          'username': username,
          'password': '$username$username',
        });
      } else {
        await users.add({'username': username, 'password': username});
      }
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

  Future<bool> checknama(String nama) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot =
          await users
              .where('nama', isEqualTo: nama)
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

  Future<bool> checkphoneNumber(String phoneNumber) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot = 
      await users
              .where('phoneNumber', isEqualTo: phoneNumber)
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

  Future<bool> checkclub(String club) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot =
          await users
              .where('club', isEqualTo: club)
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

  Future<void> editUsername(String username, String newUsername) async {
    try {
      await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get()
          .then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.update({'username': newUsername});
            }
          });
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }
  
  Future<void> editProfil(String username, String name, String club, String phoneNumber) async {
    try {
      await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get()
          .then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.update({'name': name, 'club': club, 'phoneNumber': phoneNumber});
            }
          });
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  Future<void> editPassword(String username, String newPassword) async {
    try {
      await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get()
          .then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.update({'password': newPassword});
            }
          });
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  Future<List<UserData>> getUserData(String username) async {
    try {
      List<UserData> users = [];

      QuerySnapshot snapshot =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        users.add(UserData.fromJson(doc.data() as Map<String, dynamic>));
      }

      return users;
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  Future<List<UserProfil>> getProfilData (String username) async {
    try {
      List<UserProfil> profil = [];

      QuerySnapshot snapshot =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        profil.add(UserProfil.fromJson(doc.data() as Map<String, dynamic>));
      }

      return profil;
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

  Future<List<AllCourts>> getAllLapangan() async {
    try {
      QuerySnapshot querySnapshot =
          await firestore.collection('lapangan').get();
      return querySnapshot.docs.map((doc) {
        return AllCourts.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
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
  // OPTIMIZATION 1: Use batch writes for generating time slots
  Future<void> generateSlots7day() async {
    try {
      if (_courtsCache.isEmpty) {
        final courts = await firestore.collection('lapangan').get();
        for (var court in courts.docs) {
          _courtsCache[court.id] = court.data();
        }
      }

      final today = DateTime.now();
      var batch = firestore.batch(); // Changed to var instead of final
      int batchCount = 0;
      final maxBatchSize = 500; // Firestore limit is 500 operations per batch

      for (var i = 0; i < 7; i++) {
        final targetDate = DateTime(today.year, today.month, today.day + i);
        final dateStr =
            "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

        // Get all existing slots for this date in a single query
        final allExistingSlots =
            await firestore
                .collection('time_slots')
                .where('date', isEqualTo: dateStr)
                .get();

        // Create a map for easy lookup of existing slots
        final existingSlotIds = <String>{};
        for (var doc in allExistingSlots.docs) {
          existingSlotIds.add(doc.id);
        }

        for (var courtData in _courtsCache.values) {
          final courtNumber = courtData['nomor'].toString();

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

              // Only add to batch if slot doesn't exist
              if (!existingSlotIds.contains(slotId)) {
                final slotRef = firestore.collection('time_slots').doc(slotId);
                batch.set(slotRef, {
                  'courtId': courtNumber,
                  'date': dateStr,
                  'startTime': startTime,
                  'endTime': endTimeStr,
                  'isAvailable': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                batchCount++;

                // Commit batch if we reach the limit
                if (batchCount >= maxBatchSize) {
                  await batch.commit();
                  // Create a new batch
                  batch = firestore.batch();
                  batchCount = 0;
                }
              }
            }
          }
        }
      }

      // Commit any remaining operations in the batch
      if (batchCount > 0) {
        await batch.commit();
      }

      // Clear cache after successful operation
      _timeSlotCache.clear();
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

  Future<void> generateSlotsOneDay(DateTime selectedDate) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final courts = await firestore.collection('lapangan').get();

    var batch = FirebaseFirestore.instance.batch();
    var operationCount = 0;

    for (final court in courts.docs) {
      final courtNumber = court['nomor'].toString();

      if (await _hasExistingSlots(courtNumber, dateStr)) continue;

      for (final slot in _timeSlots) {
        final [hourStr, minuteStr] = slot.split(':');
        final hour = int.parse(hourStr);
        final minute = int.parse(minuteStr);

        final slotData = _buildSlotData(courtNumber, dateStr, hour, minute);
        final slotId = '${courtNumber}_${dateStr}_${hourStr}${minuteStr}';

        batch.set(firestore.collection('time_slots').doc(slotId), slotData);
        operationCount++;

        if (operationCount % 450 == 0) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
        }
      }
    }

    if (operationCount % 450 != 0) {
      await batch.commit();
    }
  }

  Future<bool> _hasExistingSlots(String courtNumber, String dateStr) async {
    final doc =
        await firestore
            .collection('time_slots')
            .doc('${courtNumber}_${dateStr}_0700') // 检查第一个slot
            .get();
    return doc.exists;
  }

  Map<String, dynamic> _buildSlotData(
    String courtNumber,
    String dateStr,
    int hour,
    int minute,
  ) {
    final endHour = minute == 30 ? hour + 1 : hour;
    final endMinute = minute == 30 ? 0 : 30;

    return {
      'courtId': courtNumber,
      'date': dateStr,
      'startTime':
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      'endTime':
          '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
      'isAvailable': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
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
  Future<List<TimeSlot>> getTimeSlotsByTime(
    String startTime,
    String courts,
    DateTime selectedDate,
  ) async {
    try {
      final targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
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

  Future<List<TimeSlotForAdmin>> getTimeSlotsByDateForAdmin(
    DateTime selectedDate,
  ) async {
    try {
      final targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
      final QuerySnapshot querySnapshot =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .get();

      return querySnapshot.docs.map((doc) {
        return TimeSlotForAdmin.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get time slots: $e');
    }
  }

  // Fungsi untuk mengambil data slot dari Firestore berdasarkan username dan tanggal
  Future<List<TimeSlot>> getTimeSlotByUsername(
    String username,
    DateTime selectedDate,
  ) async {
    try {
      final targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedDate.hour,
        selectedDate.minute,
      );
      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      final timeStr =
          "${targetDate.hour.toString().padLeft(2, '0')}:${targetDate.minute.toString().padLeft(2, '0')}";

      final QuerySnapshot querySnapshot =
          await firestore
              .collection('time_slots')
              .where('username', isEqualTo: username)
              .where('date', isGreaterThanOrEqualTo: dateStr)
              .where('startTime', isGreaterThanOrEqualTo: timeStr)
              .get();
      return querySnapshot.docs.map((doc) {
        return TimeSlot.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get time slots for $username: $e');
    }
  }

  Future<List<TimeSlot>> getTimeSlotsByDatePaginated(
    String dateStr, {
    String? lastCourtId,
    String? lastStartTime,
    int limit = 50,
  }) async {
    try {
      // Check cache first
      final cacheKey = '${dateStr}_${lastCourtId ?? ''}_${lastStartTime ?? ''}';
      if (_timeSlotCache.containsKey(cacheKey)) {
        return _timeSlotCache[cacheKey]!;
      }

      Query query = firestore
          .collection('time_slots')
          .where('date', isEqualTo: dateStr)
          .limit(limit);

      // Apply pagination if needed
      if (lastCourtId != null && lastStartTime != null) {
        query = query.startAfter([lastCourtId, lastStartTime]);
      }

      final QuerySnapshot querySnapshot = await query.get();

      final slots =
          querySnapshot.docs.map((doc) {
            return TimeSlot.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();

      // Cache results
      _timeSlotCache[cacheKey] = slots;

      return slots;
    } catch (e) {
      throw Exception('Failed to get time slots: $e');
    }
  }

  Future<List<AllBookedUser>> getAllBookingsByUsername(String username) async {
    try {
      final QuerySnapshot querySnapshot =
          await firestore
              .collection('time_slots')
              .where('username', isEqualTo: username)
              .get();
      return querySnapshot.docs.map((doc) {
        return AllBookedUser.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get time slots for $username: $e');
    }
  }

  Future<List<LastActivity>> getLastActivity(String username) async {
    try {
      final targetDate = DateTime.now();

      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      final QuerySnapshot querySnapshot =
          await firestore
              .collection('time_slots')
              .where('username', isEqualTo: username)
              .where('date', isLessThan: dateStr)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          return LastActivity.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get time slots for $username: $e');
    }
  }

  Future<List<AvailableForMember>> getAvailableSlotsForMember(
    DateTime selectedDate,
    String startTime,
    String endTime,
  ) async {
    try {
      final targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      final existingSlots = await getTimeSlotsByDate(dateStr);

      if (existingSlots.isEmpty) {
        await generateSlotsOneDay(selectedDate);
      }

      // Fungsi bantu untuk ubah ke menit
      int timeToMinutes(String time) {
        final parts = time.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }

      // Fungsi bantu untuk ubah menit ke string format HH:mm
      String minutesToTime(int minutes) {
        final hours = (minutes ~/ 60).toString().padLeft(2, '0');
        final mins = (minutes % 60).toString().padLeft(2, '0');
        return '$hours:$mins';
      }

      int startMinutes = timeToMinutes(startTime);
      int endMinutes = timeToMinutes(endTime);

      List<AvailableForMember> availableSlots = [];

      // Loop semua slot 30 menit dari start ke end
      for (
        int slotStart = startMinutes;
        slotStart < endMinutes;
        slotStart += 30
      ) {
        final slotStartStr = minutesToTime(slotStart);
        final slotEndStr = minutesToTime(slotStart + 30);

        final QuerySnapshot querySnapshot =
            await firestore
                .collection('time_slots')
                .where('date', isEqualTo: dateStr)
                .where('startTime', isEqualTo: slotStartStr)
                .where('endTime', isEqualTo: slotEndStr)
                .where('isAvailable', isEqualTo: true)
                .get();

        // Tambahkan slot yang ditemukan
        for (var doc in querySnapshot.docs) {
          availableSlots.add(
            AvailableForMember.fromJson(doc.data() as Map<String, dynamic>),
          );
        }
      }

      return availableSlots;
    } catch (e) {
      throw Exception('Failed to get time slots: $e');
    }
  }

  Future<bool> memberOrNonmember(String username) async {
    try {
      final querySnapshot =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .where('role', isEqualTo: 'member')
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  Future<void> nonMemberToMember(String username) async {
    try {
      final querySnapshot =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('User tidak ditemukan');
      }

      final docRef = querySnapshot.docs.first.reference;

      await docRef.update({'role': 'member'});
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  // Fungsi untuk mengecek ketersediaan slot berdasarkan id dan lapangan
  Future<bool> isSlotAvailable(
    String startTime,
    String courts,
    DateTime selectedDate,
  ) async {
    try {
      final targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final dateStr =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      // Create unique slot ID
      final slotId = "${courts}_${dateStr}_${startTime.replaceAll(':', '')}";

      // Try to get directly with document ID instead of querying
      final slotDoc =
          await firestore.collection('time_slots').doc(slotId).get();

      if (slotDoc.exists) {
        final TimeSlot slot = TimeSlot.fromJson(
          slotDoc.data() as Map<String, dynamic>,
        );
        return (slot.isAvailable && !slot.isClosed);
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Failed to check slot availability: $e');
    }
  }

  Future<List<SlotStatus>> getSlotRangeAvailability({
    required String startTime,
    required String court,
    required DateTime date,
    required int maxSlots,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final query = firestore
        .collection('time_slots')
        .where('date', isEqualTo: dateStr)
        .where('courtId', isEqualTo: court)
        .where('startTime', isGreaterThan: startTime)
        .orderBy('startTime', descending: false)
        .limit(maxSlots);

    return await query.get().then(
      (snapshot) =>
          snapshot.docs.map((doc) {
            final data = doc.data();
            return SlotStatus(
              startTime: data['startTime'],
              isAvailable: data['isAvailable'],
              isClosed: data['isClosed'] ?? false,
            );
          }).toList(),
    );
  }

  // Fungsi untuk booking slot
  Future<void> bookSlotForMember(String slotId, String username) async {
    try {
      await firestore.collection('time_slots').doc(slotId).update({
        'isAvailable': false,
        'username': username,
      });
    } catch (e) {
      throw Exception('Failed to book slot: $e');
    }
  }

  Future<void> bookSlotForNonMember(
    String slotId,
    String username,
    double totalHours,
  ) async {
    try {
      final batch = firestore.batch();

      // Update the time slot
      final slotRef = firestore.collection('time_slots').doc(slotId);
      batch.update(slotRef, {'isAvailable': false, 'username': username});

      final dateStr = slotId.split('_')[1];

      // Cari user berdasarkan username
      QuerySnapshot querySnapshot =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userRef = querySnapshot.docs.first.reference;
        final userDoc = await userRef.get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;

          double currentHours =
              data.containsKey('totalHours')
                  ? (data['totalHours'] as num).toDouble()
                  : 0.0;

          double point =
              data.containsKey('point')
                  ? (data['point'] as num).toDouble()
                  : 0.0;

          String startTimeStr =
              data.containsKey('startTime') ? data['startTime'] as String : '';

          // Konversi startTime string ke DateTime
          DateTime? startTime;
          if (startTimeStr.isNotEmpty) {
            try {
              startTime = DateTime.parse(
                startTimeStr,
              ); // pastikan formatnya ISO (yyyy-MM-dd)
            } catch (_) {
              startTime = null; // Format salah
            }
          }

          DateTime now = DateTime.now();

          if (startTime == null || now.difference(startTime).inDays >= 30) {
            // Sudah 1 bulan sejak startTime, reset poin dan set startTime baru
            batch.update(userRef, {
              'totalHours': currentHours + totalHours,
              'point': totalHours,
              'startTime': dateStr, // mulai ulang
            });
          } else {
            // Belum sebulan, tambah poin seperti biasa
            batch.update(userRef, {
              'totalHours': currentHours + totalHours,
              'point': point + totalHours,
            });
          }
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to book slot: $e');
    }
  }

  Future<void> addTotalBooking(String username) async {
    try {
      final batch = firestore.batch();

      QuerySnapshot querySnapshot =
          await firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userRef = querySnapshot.docs.first.reference;
        final userDoc = await userRef.get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;

          int totalBooking =
              data.containsKey('totalBooking')
                  ? (data['totalBooking'] as num).toInt()
                  : 0;

          batch.update(userRef, {'totalBooking': totalBooking + 1});
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to book slot: $e');
    }
  }

  Future<void> bookMultipleSlots(List<String> slotIds, String username) async {
    try {
      final batch = firestore.batch();

      for (String slotId in slotIds) {
        final slotRef = firestore.collection('time_slots').doc(slotId);
        batch.update(slotRef, {'isAvailable': false, 'username': username});
      }

      await batch.commit();

      // Clear affected cache entries
      _timeSlotCache.clear();
    } catch (e) {
      throw Exception('Failed to book multiple slots: $e');
    }
  }

  Future<bool> isSlotClosed(
    String startTime,
    String courtId,
    DateTime selectedDate,
  ) async {
    try {
      final dateStr =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      final formatStartTime = startTime.split(':')[0] + startTime.split(':')[1];
      final slotId = '${courtId}_${dateStr}_$formatStartTime';

      final DocumentSnapshot slotDoc =
          await firestore.collection('time_slots').doc(slotId).get();

      if (slotDoc.exists) {
        final data = slotDoc.data() as Map<String, dynamic>;
        return data['isClosed'] ?? false;
      }
      return false;
    } catch (e) {
      throw ('Error checking if slot is closed: $e');
    }
  }

  Future<List<AllUser>> getAllUsers() async {
    try {
      final QuerySnapshot querySnapshot =
          await firestore.collection('users').get();
      return querySnapshot.docs.map((doc) {
        return AllUser.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  Future<List<AllUser>> getAllUsersPaginated({
    String? lastUsername,
    int limit = 50,
  }) async {
    try {
      Query query = firestore.collection('users').limit(limit);

      if (lastUsername != null) {
        query = query.startAfter([lastUsername]);
      }

      final QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        return AllUser.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  Future<void> closeAllDay(DateTime selectedDate) async {
    try {
      if (_courtsCache.isEmpty) {
        final courts = await firestore.collection('lapangan').get();
        for (var court in courts.docs) {
          _courtsCache[court.id] = court.data();
        }
      }

      final targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      final dateStr =
          "${targetDate.year.toString().padLeft(4, '0')}-"
          "${targetDate.month.toString().padLeft(2, '0')}-"
          "${targetDate.day.toString().padLeft(2, '0')}";

      // First, check if we have existing slots for this date
      final existingSlots =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: dateStr)
              .get();

      // If we have existing slots, update them in batches
      if (existingSlots.docs.isNotEmpty) {
        var updateBatch = firestore.batch();
        int updateCount = 0;
        final maxBatchSize = 500;

        for (var doc in existingSlots.docs) {
          updateBatch.update(doc.reference, {
            'isAvailable': true,
            'isClosed': true,
          });

          updateCount++;

          // Commit batch if we reach the limit
          if (updateCount >= maxBatchSize) {
            await updateBatch.commit();
            updateBatch = firestore.batch();
            updateCount = 0;
          }
        }

        // Commit any remaining operations
        if (updateCount > 0) {
          await updateBatch.commit();
        }
      } else {
        // If no existing slots, generate them with isClosed = true
        var createBatch = firestore.batch();
        int createCount = 0;
        final maxBatchSize = 500;

        for (var courtData in _courtsCache.values) {
          final courtNumber = courtData['nomor'].toString();

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

              final docRef = firestore.collection('time_slots').doc(slotId);

              createBatch.set(docRef, {
                'courtId': courtNumber,
                'date': dateStr,
                'startTime': startTime,
                'endTime': endTimeStr,
                'isAvailable': true,
                'isClosed': true,
                'createdAt': FieldValue.serverTimestamp(),
              });

              createCount++;

              // Commit batch if we reach the limit
              if (createCount >= maxBatchSize) {
                await createBatch.commit();
                createBatch = firestore.batch();
                createCount = 0;
              }
            }
          }
        }

        // Commit any remaining operations
        if (createCount > 0) {
          await createBatch.commit();
        }
      }

      // Add to closed_days collection
      await firestore.collection('closed_days').add({
        'date': dateStr,
        'startTime': '07:00',
        'endTime': '23:00',
        'isClosed': 'all day',
      });

      // Clear cache
      _timeSlotCache.clear();
    } catch (e) {
      throw Exception('Failed to close all day: $e');
    }
  }

  Future<void> closeUseTimeRange(
    DateTime selectedDate,
    String startTime,
    String endTime,
  ) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final courts = await firestore.collection('lapangan').get();
      final batch = firestore.batch();

      final isDateInitialized = await firestore
          .collection('time_slots')
          .where('date', isEqualTo: dateStr)
          .limit(1)
          .get()
          .then((snap) => snap.docs.isNotEmpty);

      if (!isDateInitialized) {
        await _generateFullDaySlots(selectedDate, courts);
      }

      final startMins = _timeToMinutes(startTime);
      final endMins = _timeToMinutes(endTime);

      for (final court in courts.docs) {
        final courtNumber = court['nomor'].toString();

        for (int mins = startMins; mins < endMins; mins += 30) {
          final slotId = '${courtNumber}_${dateStr}_${_formatMinutes(mins)}';
          final docRef = firestore.collection('time_slots').doc(slotId);

          batch.update(docRef, {
            'isAvailable': false,
            'isClosed': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final closeDayRef = firestore.collection('closed_days').doc();
      batch.set(closeDayRef, {
        'date': dateStr,
        'startTime': startTime,
        'endTime': endTime,
        'isClosed': 'time range',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to close range: ${e.toString()}');
    }
  }

  Future<void> _generateFullDaySlots(
    DateTime date,
    QuerySnapshot courts,
  ) async {
    final batch = firestore.batch();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    for (final court in courts.docs) {
      final courtNumber = court['nomor'].toString();

      for (int hour = 7; hour <= 22; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          final slotId =
              '${courtNumber}_${dateStr}_${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}';
          batch.set(firestore.collection('time_slots').doc(slotId), {
            'courtId': courtNumber,
            'date': dateStr,
            'startTime':
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
            'endTime':
                minute == 30
                    ? '${(hour + 1).toString().padLeft(2, '0')}:00'
                    : '${hour.toString().padLeft(2, '0')}:30',
            'isAvailable': true,
            'isClosed': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
    await batch.commit();
  }

  Future<List<AllCloseDay>> getAllCloseDay() async {
    try {
      final QuerySnapshot querySnapshot =
          await firestore.collection('closed_days').get();

      return querySnapshot.docs.map((doc) {
        return AllCloseDay.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all closed days: $e');
    }
  }

  Future<void> deleteCloseDay(String selectedDate) async {
    try {
      await firestore
          .collection('closed_days')
          .where('date', isEqualTo: selectedDate)
          .limit(1)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });

      await firestore
          .collection('time_slots')
          .where('date', isEqualTo: selectedDate)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.update({'isClosed': false});
            }
          });
    } catch (e) {
      throw Exception('Failed to delete closed day: $e');
    }
  }

  Future<void> updateCloseDay(String selectedDate) async {
    try {
      await firestore
          .collection('time_slots')
          .where('date', isEqualTo: selectedDate)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.update({'isClosed': false});
            }
          });

      await firestore
          .collection('closed_days')
          .where('date', isEqualTo: selectedDate)
          .limit(1)
          .get()
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
    } catch (e) {
      throw Exception('Failed to update closed day: $e');
    }
  }
}
