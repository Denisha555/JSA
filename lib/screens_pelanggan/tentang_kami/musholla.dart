import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

class Musholla extends StatefulWidget {
  const Musholla({super.key});

  @override
  State<Musholla> createState() => _MushollaState();
}

class _MushollaState extends State<Musholla> {
  int activeIndex = 0;
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
            Stack(
              children: [
                cs.CarouselSlider(
                  options: cs.CarouselOptions(
                    height: MediaQuery.of(context).size.width,
                    autoPlay: true,
                    autoPlayInterval: Duration(seconds: 10),
                    viewportFraction: 1.0,
                    onPageChanged: (index, reason) {
                      setState(() {
                        activeIndex = index;
                      });
                    },
                  ),
                  items: [
                    Image.asset("assets/image/Musholla1.jpeg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                    Image.asset("assets/image/Musholla2.jpeg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                    Image.asset("assets/image/Musholla3.jpg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                  ],
                ),
                Positioned(bottom: 10, left: 0, right: 0, child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [0, 1, 2].asMap().entries.map((entry) {
                    bool isActive = activeIndex == entry.key; 
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: isActive ? 25 : 10, // aktif lebih panjang
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }).toList(),
                ))
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