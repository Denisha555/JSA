import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCheckPrice {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<bool> checkPrice(
    String type,
    int jamMulai,
    int jamSelesai,
    String hariMulai,
    String hariSelesai,
  ) async {
    try {
      QuerySnapshot query = await firestore
          .collection('harga')
          .where('type', isEqualTo: type)
          .where('jam_mulai', isEqualTo: jamMulai)
          .where('jam_selesai', isEqualTo: jamSelesai)
          .where('hari_mulai', isEqualTo: hariMulai)
          .where('hari_selesai', isEqualTo: hariSelesai)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error Checking Price: $e');
    }
  }
}