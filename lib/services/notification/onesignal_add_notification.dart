import 'package:cloud_firestore/cloud_firestore.dart';

class OneSignalAddNotification {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addNotification(String id) async {
    final users = firestore.collection('users').doc('admin_1');

    await users.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        users.set({
          'notification': FieldValue.arrayUnion([id]),
        }, SetOptions(merge: true));
      }
    });
  }
}
