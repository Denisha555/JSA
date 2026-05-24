import "package:cloud_firestore/cloud_firestore.dart";

class OneSignalGetRestApi {
  Future<String?> getRestApi() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final docSnapshot = await firestore.collection('onesignal').get();
      if (docSnapshot.docs.isNotEmpty) {
        final data = docSnapshot.docs[0].data();
        return data['REST API'] as String?;
      } else {
        throw Exception('No OneSignal configuration found');
      }
    } catch (e) {
      throw Exception('Failed to get notification ID: $e');
    }
  }
}
