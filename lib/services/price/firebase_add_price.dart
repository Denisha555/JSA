import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseAddPrice {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addPrice(
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
      throw Exception('Error Saving Price: $e');
    }
  }
}