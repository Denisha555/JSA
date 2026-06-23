import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/jadwal_khusus_model.dart';
import 'package:intl/intl.dart';

class FirebaseGetJadwal {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<List<JadwalKhususModel>> getJadwal(DateTime date) async {
    try {
      QuerySnapshot querySnapshot =
          await firestore.collection('jadwal_khusus').get();

      List<JadwalKhususModel> jadwalList = [];

      if (querySnapshot.docs.isEmpty) {
        return [];
      } else {
        for (var doc in querySnapshot.docs) {
          if (doc['date'] == DateFormat('yyyy-MM-dd').format(date)) {
            jadwalList.add(
              JadwalKhususModel.fromJson(doc.data() as Map<String, dynamic>),
            );
          }
        }
      }
      return jadwalList;
    } catch (e) {
      throw Exception("Error getting jadwal: $e");
    }
  }
}
