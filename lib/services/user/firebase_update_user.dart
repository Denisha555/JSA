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
        await firestore.collection('users').doc(username).update({
          field: value,
        });
        
        final doc = await firestore.collection('users').doc(username).get();
        final data = doc.data()!;
        await firestore.collection('users').doc(value).set(data);
        await firestore.collection('users').doc(username).delete();
        
      } else {
        throw Exception('User does not exist');
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  Future<void> updateProfil(
    String username,
    String name,
    String club,
    String phoneNumber,
  ) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence('username', username);
      
      if (exist) {
        await firestore.collection('users').doc(username).update({
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
