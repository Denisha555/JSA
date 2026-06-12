import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class FirebaseUpdateUser {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> updateUser(String field, String username, value) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );
      if (exist) {
        QuerySnapshot result =
            await firestore
                .collection('users')
                .where('username', isEqualTo: username)
                .get();
        
        var docId = result.docs[0].id;

        await firestore.collection('users').doc(docId).set({
          field: value,
      }, SetOptions(merge: true));

        // final doc = await firestore.collection('users').doc(docId).get();
        // final data = doc.data()!;
        // await firestore.collection('users').doc(docId).set(data);
      } else {
        throw Exception('User does not exist');
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  Future<void> updateManyData(Map<String, dynamic> data, String username) async {
    try {
      final result = await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      var docId = result.docs[0].id;

      await firestore.collection('users').doc(docId).set(
        data, SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Error update many data user: $e');
    }
  }

  Future<void> updateProfil(
    String username,
    String name,
    String club,
    String phoneNumber,
  ) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );

      if (exist) {
        QuerySnapshot result =
            await firestore
                .collection('users')
                .where('username', isEqualTo: username)
                .get();
        var docId = result.docs[0].id;

        await firestore.collection('users').doc(docId).update({
          'name': name,
          'club': club,
          'phoneNumber': phoneNumber,
        });
      } else {
        throw Exception('User does not exist');
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }
}
