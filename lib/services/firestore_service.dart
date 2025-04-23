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
      QuerySnapshot querySnapshot =
          await users.where('username', isEqualTo: userName).get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error Checking User: $e');
    }
  }

  // Fungsi untuk mengecek apakah password user benar
  Future<bool> checkPassword(String userName, String password) async {
    try {
      CollectionReference users = firestore.collection('users');
      QuerySnapshot querySnapshot =
          await users
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

  // Fungsi untuk menyimpan gambar promo dan event ke Firestore
  Future<void> savePromoEventImage(String imageUrl) async {
    try {
      CollectionReference promoevent = firestore.collection('promoevent');
      await promoevent.add({'image': imageUrl});
    } catch (e) {
      throw Exception('Error Saving Image: $e');
    }
  }

  // Fungsi untuk menghapus gambar promo dan event di Firestore
  Future<void> deletePromoEventImage(String imageUrl) async {
    try {
      CollectionReference promoevent = firestore.collection('promoevent');
      QuerySnapshot querySnapshot =
          await promoevent.where('image', isEqualTo: imageUrl).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        await documentSnapshot.reference.delete();
      }
    } catch (e) {
      throw Exception('Error Deleting Image: $e');
    }
  }

  // Fungsi untuk menyimpan harga ke Firestore
  Future<void> saveHarga(
    String type,
    int jamMulai,
    int jamSelesai,
    String hariMulai,
    String hariSelesai,
    int harga,
  ) async {
    try {
      CollectionReference hargaCollection = firestore.collection('harga');
      await hargaCollection.add({
        'type': type,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'hari_mulai': hariMulai,
        'hari_selesai': hariSelesai,
        'harga': harga,
      });
    } catch (e) {
      throw Exception('Error Saving Harga: $e');
    }
  }

  // Fungsi untuk cek data harga di Firestore
  Future<bool> checkHarga(
    String type,
    int jamMulai,
    int jamSelesai,
    String hariMulai,
    String hariSelesai,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await firestore
              .collection('harga')
              .where('type', isEqualTo: type)
              .where('jam_mulai', isEqualTo: jamMulai)
              .where('jam_selesai', isEqualTo: jamSelesai)
              .where('hari_mulai', isEqualTo: hariMulai)
              .where('hari_selesai', isEqualTo: hariSelesai)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error Checking Harga: $e');
    }
  }

  // Fungsi untuk mendapatkan ID dokumen dari harga
  Future<String?> getHargaDocumentId(
    String type,
    int jamMulai,
    int jamSelesai,
    String hariMulai,
    String hariSelesai,
  ) async {
    try {
      QuerySnapshot querySnapshot =
          await firestore
              .collection('harga')
              .where('type', isEqualTo: type)
              .where('jam_mulai', isEqualTo: jamMulai)
              .where('jam_selesai', isEqualTo: jamSelesai)
              .where('hari_mulai', isEqualTo: hariMulai)
              .where('hari_selesai', isEqualTo: hariSelesai)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      throw Exception('Error Getting Harga Document ID: $e');
    }
  }

  // Fungsi untuk menambahkan lapangan ke Firestore
  Future<void> tambahLapangan({
    required String nomor,
    required String deskripsi,
    String? imageUrl,
  }) async {
    try {
      CollectionReference lapanganCollection = firestore.collection('lapangan');
      await lapanganCollection.add({
        'nomor': nomor,
        'deskripsi': deskripsi,
        'image': imageUrl,
      });
    } catch (e) {
      throw Exception('Error menambahkan lapangan: $e');
    }
  }

  // Fungsi untuk update lapangan di Firestore
  Future<void> updateLapangan({
    required String documentId,
    required String nomor,
    Timestamp? createdAt,
    String? deskripsi,
    String? imageUrl,
  }) async {
    try {
      CollectionReference lapanganCollection = firestore.collection('lapangan');
      await lapanganCollection.doc(documentId).update({
        'nomor': nomor,
        'deskripsi': deskripsi,
        'image': imageUrl,
      });
    } catch (e) {
      throw Exception('Error mengupdate lapangan: $e');
    }
  }

  // Fungsi untuk mengecek apakah lapangan sudah ada di Firestore
  Future<bool> checkLapangan(String nomor) async {
    try { QuerySnapshot querySnapshot =
          await firestore
              .collection('lapangan')
              .where('nomor', isEqualTo: nomor)
              .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e){
      throw Exception('Error Checking Lapangan: $e');
    }
  }

  // Fungsi untuk menghapus lapangan di Firestore
  Future<void> hapusLapangan(String docId) async {
    try {
      CollectionReference lapanganCollection = firestore.collection('lapangan');
      await lapanganCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('Error menghapus lapangan: $e');
    }
  }

  // Fungsi untuk menambahkan promo dan event ke Firestore
  Future<void> tambahPromoEvent({required String imageurl}) async {
    try {
      CollectionReference promoEventCollection = firestore.collection(
        'promo_event',
      );
      await promoEventCollection.add({'gambar': imageurl});
    } catch (e) {
      throw Exception('Failed to create promo event: $e');
    }
  }

  Future<void> deletePromoEvent(String id) async {
    try {
      CollectionReference promoEventCollection = firestore.collection('promo_event');
      await promoEventCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete promo event: $e');
    }
  }
}
