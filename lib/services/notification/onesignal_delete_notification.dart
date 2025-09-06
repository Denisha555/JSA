import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OnesignalDeleteNotification {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> deleteNotification(String id) async {
    final users = firestore.collection('users').doc('admin_1');

    await users.get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        users.update({
          'notification': FieldValue.arrayRemove([id]),
        });
      }
    });

    await OneSignal.User.removeTag("role");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('admin_id');
  }
}
