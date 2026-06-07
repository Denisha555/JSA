import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAddUser {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addUser({
    required String userId,
    required String userName,
    required String password,
    required String role,
    String? name,
    String? club,
    String? phoneNumber,
  }) async {
    try {
      CollectionReference users = firestore.collection('users');
      await users.doc(userId).set({
        'userId': userId,
        'username': userName,
        'password': password,
        'role': role,
        'startTimePoint': '',
        'point': 0,
        'hour': 0,
        'totalBooking': 0,
        'bookingDates': [],
        if (name != null) 'name': name,
        if (club != null) 'club': club,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error Adding User: $e');
    }
  }
}
