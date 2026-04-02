import 'dart:ffi';

import 'package:flutter/material.dart';

class Kantin extends StatelessWidget {
  const Kantin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kantin"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset("assets/image/Kantin1.jpeg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text("Detail Fasilitas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Kami menyediakan berbagai fasilitas pendukung untuk menunjang kenyamanan dan kelancaran aktivitas bermain badminton Anda. Mulai dari beragam pilihan snack ringan dan minuman segar yang dapat dinikmati untuk mengembalikan energi setelah bermain, hingga layanan sewa raket dengan harga yang terjangkau bagi Anda yang tidak membawa perlengkapan pribadi. Selain itu, kami juga menyediakan penjualan bola bulu tangkis berkualitas yang cocok digunakan baik untuk latihan maupun pertandingan. Untuk memastikan pengalaman bermain yang lebih teratur dan efisien, tersedia pula layanan pencatatan jadwal lapangan yang memudahkan Anda dalam melakukan reservasi dan menghindari bentrok waktu. Dengan fasilitas yang lengkap dan praktis ini, kami berkomitmen untuk memberikan pengalaman bermain badminton yang nyaman, menyenangkan, dan tanpa hambatan.", textAlign: TextAlign.justify),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}