import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/user_model.dart';

class FirebaseGetUser {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getUsers() async {
    List<UserModel> userList = [];
    try {
      QuerySnapshot snapshot = await firestore.collection('users').get();

      for (DocumentSnapshot doc in snapshot.docs) {
        userList.add(UserModel.fromJson(doc.data() as Map<String, dynamic>));
      }

      return userList;
    } catch (e) {
      throw Exception('Error Fetching Users: $e');
    } 
  }

  Future<List<UserModel>> getUserByUsername(String username) async {
    try {
      List<UserModel> userList = [];
      QuerySnapshot snapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        userList.add(UserModel.fromJson(doc.data() as Map<String, dynamic>));
      }

      return userList;
    } catch (e) {
      throw Exception('Error Fetching User by Username: $e');
    }
  }

  Future<dynamic> getUserData(String username, String field) async {
    try {
      QuerySnapshot snapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User not found');
      }
      
      return snapshot.docs[0].get(field);
    } catch (e) {
      throw Exception('Error Fetching User Data: $e');
    }
  }
}