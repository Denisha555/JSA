import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/function/price/price.dart';
import 'package:flutter_application_1/function/schedule/holiday/get_holiday.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/services/price/firebase_get_price.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:intl/intl.dart';

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

      String userId = userSnapshot.docs[0].id;

      final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;

      final List<Map<String, dynamic>> bookingDates =
            userData['bookingDates'] != null
                ? (userData['bookingDates'] as List<dynamic>)
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : [];

      List<TimeSlotModel> allSlots = [];

      for (var booking in bookingDates) {
        final bookingMap = Map<String, dynamic>.from(booking);

        final court = bookingMap['courtId'];
        final date = bookingMap['date'];
        final startTime = bookingMap['startTime'];
        final endTime = bookingMap['endTime'];
        final type = bookingMap['type'];

        allSlots.add(
          TimeSlotModel(
            courtId: court,
            date: date,
            startTime: startTime,
            endTime: endTime,
            type: type,
            isAvailable: false,
          ),
        ); 
      }
      return allSlots;
    } catch (e) {
      throw Exception('Failed to get time slots for $username: $e');
    }
  }

  Future<List<TimeSlotModel>> getCancelBookingByUsername(
    String username,
  ) async {
    try {
      final docRef =
          await firestore
              .collection('users')
              .where("username", isEqualTo: username)
              .get();

      String userId = docRef.docs[0].id;

      final data = docRef.docs.first.data();

      final List<Map<String, dynamic>> cancelDates =
            data['cancelDate'] != null
                ? (data['cancelDate'] as List<dynamic>)
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : [];

      List<TimeSlotModel> allSlots = [];

      // Loop semua tanggal cancel
      for (var data in cancelDates) {
        final bookingMap = Map<String, dynamic>.from(data);

        final court = bookingMap['courtId'];
        final date = bookingMap['date'];
        final startTime = bookingMap['startTime'];
        final endTime = bookingMap['endTime'];
        final type = bookingMap['type'];

        allSlots.add(
          TimeSlotModel(
            courtId: court,
            date: date,
            startTime: startTime,
            endTime: endTime,
            type: type,
            isAvailable: false,
          ),
        );
      }

      return allSlots;
    } catch (e) {
      throw Exception('Failed to get cancel time slots for $username: $e');
    }
  }

  Future<List<TimeSlotModel>> getBookingByDate(DateTime date) async {
    try {
      final timeSlotsSnapshot =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: formatDateStr(date))
              .get();

      List<TimeSlotModel> allSlots = [];

      for (var doc in timeSlotsSnapshot.docs) {
        final slots = doc.data()['slots'] as List<dynamic>;
        for (var slot in slots) {
          if (slot["isAvailable"] == false && slot["isClosed"] == false) {
            String userId = slot['userId'] ?? '';
            slot['username'] = await FirebaseGetUser().getUserDataById(
              userId,
              'username',
            );
            allSlots.add(
              TimeSlotModel.fromJson(
                slot,
                courtId: doc.id,
                date: formatStrToLongDate(
                  DateFormat('yyyy-MM-dd').format(date),
                ),
              ),
            );
          }
        }
      }

      if (allSlots.isEmpty) {
        return [];
      }

      return allSlots;
    } catch (e) {
      throw Exception('Failed to get booking by date: $e');
    }
  }

  Future<int> getTodayCustomers() async {
    try {
      QuerySnapshot timeSlotsSnapshot =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: formatDateStr(DateTime.now()))
              .get();

      Set<String> customers = {};

      for (var doc in timeSlotsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final slots = data['slots'] as List<dynamic>? ?? [];
        for (var slot in slots) {
          final userId = slot['userId'] as String?;
          if (userId != null && userId.isNotEmpty) {
            customers.add(userId);
          }
        }
      }

      return customers.length;
    } catch (e) {
      throw Exception('Failed to get today customers: $e');
    }
  }

  Future<double> getTodayIncome() async {
    try {
      QuerySnapshot timeSlotsSnapshot =
          await firestore
              .collection('time_slots')
              .where('date', isEqualTo: formatDateStr(DateTime.now()))
              .get();

      double totalIncome = 0;

      for (var doc in timeSlotsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final slots = data['slots'] as List<dynamic>? ?? [];
        for (var slot in slots) {
          final userId = slot['userId'] as String?;
          if (userId != null && userId.isNotEmpty) {
            var price = totalPrice(
              startTime: slot['startTime'] as String,
              endTime: slot['endTime'] as String,
              selectedDate: DateTime.now(),
              type: slot['type'] as String,
            );
            totalIncome += await price;
          }
        }
      }

      return totalIncome;
    } catch (e) {
      throw Exception('Failed to get today income: $e');
    }
  }

  Future<Map<String, int>> getWeeklyBookings() async {
    try {
      // Get tanggal 7 hari terakhir
      DateTime now = DateTime.now();
      DateTime startDate = now.subtract(Duration(days: 6));

      // Inisialisasi map untuk 7 hari dengan 0 booking
      Map<String, int> weeklyData = {};
      List<String> dayNames = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];

      // Inisialisasi semua hari dengan 0
      for (int i = 6; i >= 0; i--) {
        DateTime date = now.subtract(Duration(days: i));
        String dayName = dayNames[date.weekday % 7];
        weeklyData[dayName] = 0;
      }

      // Loop untuk setiap hari dalam 7 hari terakhir
      for (int i = 6; i >= 0; i--) {
        DateTime targetDate = now.subtract(Duration(days: i));
        String dateString = formatDateStr(targetDate);
        String dayName = dayNames[targetDate.weekday % 7];

        // Query documents dengan tanggal tertentu
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance
                .collection('time_slots') // Sesuaikan nama collection
                .where('date', isEqualTo: dateString)
                .get();

        int dailyBookings = 0;

        // Hitung booking untuk hari ini
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;

          if (data['slots'] != null) {
            List<dynamic> slots = data['slots'];
            String previousUserId = '';

            // Hitung slot yang sudah dibooking (username tidak kosong)
            for (var slot in slots) {
              if (slot is Map<String, dynamic>) {
                String userId = slot['userId'] ?? '';
                bool isAvailable = slot['isAvailable'] ?? true;

                // slot terbooking
                bool isBooked = userId.isNotEmpty || !isAvailable;

                // hanya hitung kalau:
                // - memang booking
                // - username beda dari sebelumnya
                if (isBooked && userId != previousUserId) {
                  dailyBookings++;
                }

                // simpan username sekarang
                previousUserId = userId;
              }
            }
          }
        }

        weeklyData[dayName] = dailyBookings;
      }

      return weeklyData;
    } catch (e) {
      throw Exception('Failed to get weekly bookings: $e');
    }
  }

  Future<List<TimeSlotModel>> getBookingForReport(
    String startDate,
    String endDate,
    String status,
  ) async {
    try {
      QuerySnapshot timeSlotsSnapshot =
          await firestore
              .collection('time_slots')
              .where('date', isGreaterThan: startDate)
              .where('date', isLessThan: endDate)
              .get();

      if (timeSlotsSnapshot.docs.isEmpty) {
        return [];
      }

      final hargaList = await FirebaseGetPrice().getHarga();
      final holiday = await GetHoliday().getAllHolidays();

      final userData = await FirebaseGetUser().getAllUsers();

      List<TimeSlotModel> allSlots = [];

      for (var doc in timeSlotsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final slots = data['slots'] as List<dynamic>? ?? [];
        final filterSlots =
            slots.where((slot) {
              if (status == "member") {
                return slot["type"] == "member";
              } else if (status == "nonMember") {
                return slot["type"] == "nonMember";
              }
              return true;
            }).toList();

        for (var slot in filterSlots) {
          if (slot["isAvailable"] == false) {
            double price = await totalPrice(
              startTime: slot['startTime'] as String,
              endTime: slot['endTime'] as String,
              selectedDate: DateTime.parse(doc.id.split('_')[1]),
              type: slot['type'] as String,
              hargaList: hargaList,
              holiday: holiday,
            );

            final username = userData
                .firstWhere((user) => user.userId == slot['userId'].toString())
                .username;

            allSlots.add(
              TimeSlotModel.fromJson(
                Map<String, dynamic>.from(slot),
                courtId: doc.id.split('_')[0],
                date: doc.id.split('_')[1],
                price: price,
                username: username,
              ),
            );

          } else {
            allSlots.add(
              TimeSlotModel.fromJson(
                Map<String, dynamic>.from(slot),
                courtId: doc.id.split('_')[0],
                date: doc.id.split('_')[1],
                price: 0,
              ),
            );
          }
        }
      }
      return allSlots;
    } catch (e) {
      throw Exception('Failed to get all bookings: $e');
    }
  }
}
