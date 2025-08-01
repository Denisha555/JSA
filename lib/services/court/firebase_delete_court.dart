import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseDeleteCourt {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> deleteCourt(String docId) async {
    try {
      CollectionReference lapanganCollection = firestore.collection('lapangan');
      await lapanganCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('Error Deleting court: $e');
    }
  }
}