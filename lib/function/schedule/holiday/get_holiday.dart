import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/jadwal_khusus_model.dart';

class GetHoliday {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<JadwalKhususModel>> getAllHolidays() async {
    try {
      final qs = await firestore.collection('jadwal_khusus').get();

      final data =
          qs.docs
              .map((e) => JadwalKhususModel.fromJson(e.data()))
              .where((e) => e.type == 'holiday')
              .toList();

      data.sort((a, b) => b.date.compareTo(a.date));

      return data;
    } catch (e) {
      throw Exception('Error getting holiday: $e');
    }
  }
}
