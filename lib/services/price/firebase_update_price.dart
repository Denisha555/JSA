import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUpdatePrice {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updatePrice(
    String type,
    int jamMulai,
    int jamSelesai,
    String hariMulai,
    String hariSelesai,
    int harga,
  ) async {
    try {
      // Query untuk cari document yang cocok
      QuerySnapshot query = await firestore
          .collection('harga')
          .where('type', isEqualTo: type)
          .where('jam_mulai', isEqualTo: jamMulai)
          .where('jam_selesai', isEqualTo: jamSelesai)
          .where('hari_mulai', isEqualTo: hariMulai)
          .where('hari_selesai', isEqualTo: hariSelesai)
          .get();
      
      if (query.docs.isNotEmpty) {
        // Update document yang ketemu
        await query.docs.first.reference.update({
          'harga': harga,
        });
      } else {
        throw Exception('Document not found for update');
      }
    } catch (e) {
      throw Exception('Error Updating Price: $e');
    }
  }
}