import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/price/firebase_get_price.dart';
import 'package:flutter_application_1/function/schedule/holiday/get_holiday.dart';

Future<double> totalPrice({
  required String startTime,
  required String endTime,
  required DateTime selectedDate,
  required dynamic type,
}) async {
  final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
  final hargaList = await FirebaseGetPrice().getHarga();
  final holiday = await GetHoliday().getAllHolidays();
  final isHoliday = holiday.any((item) => item.date == dateStr);

  // debugPrint(
  //   'startTime: $startTime, endTime: $endTime, date: $dateStr, type: $type',
  // );

  final hariBooking = namaHari(selectedDate.weekday);
  final startMinutes = timeToMinutes(startTime);
  final endMinutes = timeToMinutes(endTime);

  // debugPrint('startMinutes: $startMinutes, endMinutes: $endMinutes');
  // debugPrint('hariBooking: $hariBooking');

  double totalPrice = 0;

  for (int time = startMinutes; time < endMinutes; time += 30) {
    final hargaMatch = hargaList.firstWhere(
      (harga) {
        final hargaStartMinutes = harga.jamMulai * 60;
        final hargaEndMinutes = harga.jamSelesai * 60;

        final cocokHari =
            isHoliday
                ? type == 'member'
                    ? isHariInRange(
                      hariBooking,
                      harga.hariMulai,
                      harga.hariSelesai,
                    )
                    : harga.hariMulai == "Libur" && harga.hariSelesai == "Libur"
                : isHariInRange(
                  hariBooking,
                  harga.hariMulai,
                  harga.hariSelesai,
                );

        // debugPrint('type: $type, cocokHari: $cocokHari, time: $time, hargaStartMinutes: $hargaStartMinutes, hargaEndMinutes: $hargaEndMinutes');

        return harga.type == type &&
            cocokHari &&
            time >= hargaStartMinutes &&
            time < hargaEndMinutes;
      },
      orElse: () {
        throw Exception(
          'Tidak ada harga ditemukan untuk waktu $time pada tanggal $dateStr (type: $type)',
        );
      },
    );
    totalPrice += hargaMatch.harga/2;
  }

  return totalPrice;
}
