import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Musholla extends StatelessWidget {
  const Musholla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Musholla"),
      ),
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
                Image.asset("assets/image/Musholla1.jpeg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                Image.asset("assets/image/Musholla2.jpeg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                Image.asset("assets/image/Musholla3.jpeg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text("Detail Fasilitas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Bagi pengunjung yang ingin menunaikan ibadah sholat di sela-sela waktu bermain, kami menyediakan fasilitas mushola yang nyaman dan mudah diakses, terletak di lantai 2. Lokasinya berada tepat di sebelah kantin mini, sehingga tetap praktis dijangkau tanpa mengganggu aktivitas Anda. Mushola ini dilengkapi dengan tempat wudhu yang bersih dan terawat, sehingga memberikan kenyamanan lebih dalam beribadah. Selain itu, tersedia juga area khusus di dekat tangga untuk meletakkan alas kaki, sehingga lingkungan tetap rapi, bersih, dan tertata dengan baik. Dengan fasilitas ini, kami berharap pengunjung dapat tetap menjalankan ibadah dengan tenang tanpa harus meninggalkan area terlalu jauh.", textAlign: TextAlign.justify),
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