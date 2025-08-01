import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/price_model.dart';


class FirebaseGetPrice {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  Future<List<PriceModel>> getHarga() async {
    try {
      List<PriceModel> hargaList = [];

      QuerySnapshot snapshot = await firestore.collection('harga').get();

      for (DocumentSnapshot doc in snapshot.docs) {
        hargaList.add(PriceModel.fromJson(doc.data() as Map<String, dynamic>));
      }
      return hargaList;
    } catch (e) {
      throw Exception('Error to get the price: $e');
    }
  }
}