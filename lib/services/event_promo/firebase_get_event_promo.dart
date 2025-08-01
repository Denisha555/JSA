import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/event_promo_model.dart';


class FirebaseGetEventPromo {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<EventPromoModel>> getPromo() async {
    try {
      List<EventPromoModel> promo = [];

      QuerySnapshot snapshot = await firestore.collection('promo_event').get();

      for (DocumentSnapshot doc in snapshot.docs) {
        promo.add(EventPromoModel.fromJson(doc.data() as Map<String, dynamic>));
      }

      return promo;
    } catch (e) {
      throw Exception('Error to get the promo: $e');
    }
  }
}