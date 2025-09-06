import 'package:cloud_firestore/cloud_firestore.dart';

class OnesignalGetNotification {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<String>> getNotification() async {
    try {
      final docSnapshot = await firestore.collection('users').doc('admin_1').get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return data['notification'] != null
            ? List<String>.from(data['notification'])
            : [];
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get notifications id: $e');
    }
  }
}
