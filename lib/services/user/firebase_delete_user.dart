import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';

class FirebaseDeleteUser {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> deleteUser(String userName) async {
    try {
      final exist = await FirebaseCheckUser().checkExistence(
        'username',
        userName,
      );
      if (exist) {
        await firestore.collection('users').doc(userName).delete();
      } else {
        throw Exception('User does not exist');
      }
    } catch (e) {
      throw Exception('Error Deleting user: $e');
    }
  }
}
