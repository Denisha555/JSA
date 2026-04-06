import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

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
            cs.CarouselSlider(
              options: cs.CarouselOptions(
                height: MediaQuery.of(context).size.width,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 10),
                viewportFraction: 1.0,
              ),
              items: [
                Image.asset(
                  "assets/image/Lapangan1.jpg",
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
                  "assets/image/Lapangan2.jpg",
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
                    "Lapangan terjaga bersih dan nyaman digunakan untuk bermain, baik santai maupun kompetitif. Tersedia juga kursi wasit yang bisa digunakan untuk memantau jalannya pertandingan atau mencatat skor. Selain itu, tersedia phone holder bagi yang ingin merekam permainan dengan lebih praktis. Area lapangan juga dilengkapi CCTV untuk menjaga keamanan dan memastikan aktivitas tetap terpantau.",
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
