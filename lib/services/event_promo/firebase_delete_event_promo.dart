import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseDeleteEventPromo {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> deleteEventPromo(String docId) async {
    try {
      CollectionReference promoevent = firestore.collection('promo_event');
      await promoevent.doc(docId).delete();
    } catch (e) {
      throw Exception('Error Deleting Image: $e');
    }
  }
}