import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:uuid/uuid.dart';

class OneSignalAddNotificationAdmin {
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

class OnesignalAddNotificationCustomer {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> addNotification(String username) async {
    var uuid = Uuid();
    String notificationId = uuid.v4();

    await FirebaseUpdateUser().updateUser(
      'notificationId',
      username,
      notificationId,
    );

    await OneSignal.login(notificationId);
  }
}
