import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirebaseCheckJadwal {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
    Future<bool> isClosedAllTimeBefore (DateTime date) async {
    try {
      QuerySnapshot querySnapshot =
          await firestore.collection('jadwal_khusus').get();
      
      if (querySnapshot.docs.isEmpty) {
        return false;
      } else {
        for (var doc in querySnapshot.docs) {
          if (doc['date'] == DateFormat('yyyy-MM-dd').format(date)) {
            if (doc['description'] == 'all day') {
              return true;
            } else {
              return false;
            }
          }
        }
      }
      return false;
    } catch (e) {
      // Handle any errors that occur during the query
      throw Exception('Error Checking jadwal: $e');
    }
    }
      
}