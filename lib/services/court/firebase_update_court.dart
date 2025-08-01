import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseUpdateCourt {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateCourt(String docId, String courtId, {String description = '', String imageUrl = ''}) async {
    try {
      CollectionReference courts = firestore.collection('lapangan');
      await courts.doc(docId).update({
        'nomor': courtId,
        'deskripsi': description,
        'image': imageUrl,
      });
    } catch (e) {
      throw Exception('Error Updating Court: $e');
    }
  }
}