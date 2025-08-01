import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseCheckCourt {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkCourt(String courtId) async {
    try {
      QuerySnapshot querySnapshot =
        await _firestore
            .collection('lapangan')
            .where('nomor', isEqualTo: courtId)
            .get();
    return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking court: $e');
    }
  }
}