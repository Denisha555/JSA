import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

const Color primaryColor = Color.fromRGBO(42, 92, 170, 1);
const Color backgroundColor = Colors.white;
const double defaultPadding = 20.0;
const double buttonHeight = 50.0;
const double borderRadius = 10.0;

const Color availableColor = Color.fromARGB(255, 209, 250, 209);
const Color bookedColor = Color(0xFFFAE0E0);
const Color closedColor = Color(0xFFF0F0F0);
const Color holidayColor = Color.fromARGB(255, 215, 235, 250);

const List<String> timeSlots = [
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

String namaHari(int weekday) {
  const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  return hari[weekday - 1];
}

bool isHariInRange(String hariTarget, String hariMulai, String hariSelesai) {
  const urutanHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  final indexTarget = urutanHari.indexOf(hariTarget);
  final indexMulai = urutanHari.indexOf(hariMulai);
  final indexSelesai = urutanHari.indexOf(hariSelesai);

  if (indexTarget == -1 || indexMulai == -1 || indexSelesai == -1) {
    return false;
  }

  if (indexMulai <= indexSelesai) {
    return indexTarget >= indexMulai && indexTarget <= indexSelesai;
  } else {
    // Untuk kasus seperti Sabtu - Selasa (range menyeberang minggu)
    return indexTarget >= indexMulai || indexTarget <= indexSelesai;
  }
}

String formatLongDate(DateTime date) {
  List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  List<String> days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatStrToLongDate(String dateStr) {
  final date = DateTime.parse(dateStr);
  return formatLongDate(date);
}

int timeToMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String minutesToFormattedTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String calculateEndTime(String startTime, int durationSlots) {
  final startTotalMinutes = timeToMinutes(startTime);
  final endTotalMinutes = startTotalMinutes + (durationSlots * 30);
  return minutesToFormattedTime(endTotalMinutes);
}

String calculateEndTimeUseStartTime(String startTime) {
  final parts = startTime.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final endHour = minute == 30 ? hour + 1 : hour;
  final endMinute = minute == 30 ? 0 : 30;
  return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
}

int getDayIndex(String day) {
  const days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
    'Libur',
  ];
  return days.indexOf(day);
}

String getMonth(int month) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'Oktober',
    'November',
    'Desember'
  ];
  return months[month];
}

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString(); // ini hasil hash-nya
}

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

String formatDateStr(DateTime selectedDate) {
  return DateFormat('yyyy-MM-dd').format(selectedDate);
}

String formatTime(DateTime time) {
  return DateFormat('HH:mm').format(time);
}

String formatPrice(int price) {
  return NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(price);
}

String formatJam(int jam) => jam < 10 ? '0$jam.00' : '$jam.00';

String formatTimeOfDay24(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute'; // contoh: 15:00
}