import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/jadwal_khusus_model.dart';

class GetHoliday {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<JadwalKhususModel>> getAllHolidays() async {
    try {
      QuerySnapshot querySnapshot =
          await firestore
              .collection('jadwal_khusus')
              .where('type', isEqualTo: 'holiday')
              .orderBy('date', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        return JadwalKhususModel.fromJson(
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error getting holiday: $e');
    }
  }
}
