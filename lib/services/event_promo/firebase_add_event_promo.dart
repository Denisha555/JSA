import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAddEventPromo {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addEventPromo(String imageUrl, DateTime createdAt) async {
    try {
      CollectionReference promoevent = firestore.collection('promo_event');
      await promoevent.add({'gambar': imageUrl, 'createdAt': createdAt});
    } catch (e) {
      throw Exception('Error Saving Image: $e');
    }
  }
}