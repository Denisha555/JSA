import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

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
            cs.CarouselSlider(
              options: cs.CarouselOptions(
                height: MediaQuery.of(context).size.width,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 10),
                viewportFraction: 1.0,
              ),
              items: [
                Image.asset("assets/image/Kantin1.jpg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                Image.asset("assets/image/Kantin2.jpg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                Image.asset("assets/image/Kantin3.jpg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
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
                  Text("Kantin menyediakan berbagai pilihan makanan serta minuman segar yang dapat dinikmati sebelum maupun setelah bermain. Pilihan yang tersedia cukup beragam dan praktis untuk membantu mengembalikan energi setelah beraktivitas di lapangan. Area kantin juga menjadi tempat yang nyaman untuk beristirahat sejenak sambil menunggu giliran bermain.", textAlign: TextAlign.justify),
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