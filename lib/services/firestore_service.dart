import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Fungsi untuk menambahkan user ke Firestore
  Future<void> addUser(String userName, String password) async {
    try {
      CollectionReference users = firestore.collection('users');
      await users.add({'username': userName, 'password': password});
      } catch (e) {
      throw Exception('Error Adding User: $e');
    }
  }

  // Fungsi untuk mengecek apakah user ada di Firestore
  Future<bool> checkUser(String userName) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot = await users
          .where('username', isEqualTo: userName)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false; 
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  Future<bool> checkPassword(String userName, String password) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot = await users
          .where('username', isEqualTo: userName)
          .where('password', isEqualTo: password)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false; 
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }
}