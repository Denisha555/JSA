import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/court_model.dart';

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

  Future<List<CourtModel>> checkOtherCourt(String courtId) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('lapangan')
              .where('nomor', isEqualTo: courtId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<CourtModel> courts =
            querySnapshot.docs.map((doc) {
              return CourtModel.fromJson(doc.data() as Map<String, dynamic>);
            }).toList();
        return courts;
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Error checking court: $e');
    }
  }
}
