import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseAddCourt {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addCourt(String courtId, {String description = '', String imageUrl = ''}) async {
    try {
      CollectionReference courts = firestore.collection('lapangan');
      await courts.add({
        'nomor': courtId,
        'deskripsi': description,
        'image': imageUrl,
      });
    } catch (e) {
      throw Exception('Error Saving court: $e');
    }
  }
}