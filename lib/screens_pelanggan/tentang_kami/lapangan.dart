import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Lapangan extends StatelessWidget {
  const Lapangan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lapangan")),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: MediaQuery.of(context).size.width,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 10),
                viewportFraction: 1.0,
              ),
              items: [
                Image.asset(
                  "assets/image/Lapangan1.jpeg",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width,
                ),
                Image.asset(
                  "assets/image/Lapangan3.jpeg",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width,
                ),
                Image.asset(
                  "assets/image/Lapangan2.jpeg",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text(
                    "Detail Fasilitas",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Kondisi lapangan kami cukup bersih dan terawat sehingga nyaman digunakan untuk bermain, baik santai maupun kompetitif, serta dilengkapi dengan area khusus untuk juri/wasit yang mendukung jalannya pertandingan. Selain itu, tersedia juga phone holder bagi Anda yang ingin merekam permainan dengan lebih praktis, serta dilengkapi CCTV untuk menjaga keamanan dan memastikan seluruh aktivitas di area lapangan tetap terpantau dengan baik.",
                    textAlign: TextAlign.justify,
                  ),
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
