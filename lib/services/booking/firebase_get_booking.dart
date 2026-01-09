import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/function/price/price.dart';
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

      final uniqueBookingDates = bookingDates.toSet().toList();

      List<TimeSlotModel> allSlots = [];

      for (var date in uniqueBookingDates) {
        final timeSlots =
            await firestore
                .collection('time_slots')
                .where('date', isEqualTo: date)
                .get();

        for (var doc in timeSlots.docs) {
          final slots = doc.data()['slots'] as List<dynamic>;
          for (var slot in slots) {
            if (slot['username'] == username) {
              allSlots.add(
                TimeSlotModel.fromJson(
                  slot,
                  date: date,
                  courtId: doc.id.split('_')[0],
                ),
              );
              print(
                'Found slot for $username on $date: ${slot['startTime']} - ${slot['endTime']}',
              );
              print('Court ID: ${doc.id.split('_')[0]}');
            }
          }
        }
      }
      print('allSlots: ${allSlots.length}');
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

      print('cancel date: $cancelDate');

      // Kalau tidak ada cancelDate, return list kosong
      if (cancelDate == null || cancelDate.isEmpty) {
        return [];
      }

      final uniqueCancelDates = cancelDate.toSet().toList();

      List<TimeSlotModel> allSlots = [];

      // Loop semua tanggal cancel
      for (var date in uniqueCancelDates) {
        final timeSlots =
            await firestore
                .collection('time_slots')
                .where('date', isEqualTo: date)
                .get();

        for (var doc in timeSlots.docs) {
          final slots = doc.data()['slots'] as List<dynamic>;
          for (var slot in slots) {
            print('cancel slot: $slot');
            if (slot['cancel'].contains(username)) {
              allSlots.add(
                TimeSlotModel.fromJson(
                  Map<String, dynamic>.from(slot),
                  courtId: doc.id.split('_')[0],
                  date: doc.id.split('_')[1],
                ),
              );
            }
          }
        }
      }

      print('allslot: $allSlots');

      return allSlots;
    } catch (e) {
      throw Exception('Failed to~ get cancel time slots for $username: $e');
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
          if (slot["isAvailable"] == false) {
            allSlots.add(TimeSlotModel.fromJson(slot, courtId: doc.id));
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
          final username = slot['username'] as String?;
          if (username != null && username.isNotEmpty) {
            customers.add(username);
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
          final username = slot['username'] as String?;
          if (username != null && username.isNotEmpty) {
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

            // Hitung slot yang sudah dibooking (username tidak kosong)
            for (var slot in slots) {
              if (slot is Map<String, dynamic>) {
                String username = slot['username'] ?? '';
                bool isAvailable = slot['isAvailable'] ?? true;

                // Jika username ada (tidak kosong) atau isAvailable false, berarti sudah dibooking
                if (username.isNotEmpty || !isAvailable) {
                  dailyBookings++;
                }
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

  Future<List<TimeSlotModel>> getBookingForReport(String startDate, String status) async {
    try {
      QuerySnapshot timeSlotsSnapshot =
          await firestore.collection('time_slots')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .get();

      if (timeSlotsSnapshot.docs.isEmpty) {
        return [];
      }

      List<TimeSlotModel> allSlots = [];

      for (var doc in timeSlotsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final slots = data['slots'] as List<dynamic>? ?? [];
        final filterSlots = slots.where((slot) {
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
            );

            allSlots.add(
              TimeSlotModel.fromJson(
                Map<String, dynamic>.from(slot),
                courtId: doc.id.split('_')[0],
                date: doc.id.split('_')[1],
                price: price,
              ),
            );

            print('price: $price');
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
