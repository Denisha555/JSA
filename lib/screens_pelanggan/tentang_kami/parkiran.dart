import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

class Parkiran extends StatelessWidget {
  const Parkiran({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Parkiran"),
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
                Image.asset("assets/image/Parkiran1.jpg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                Image.asset("assets/image/Parkiran2.jpg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
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
                  Text("Bagi Anda yang membawa kendaraan, tidak perlu khawatir karena kami menyediakan area parkir yang cukup luas dan mudah diakses. Lokasinya berada tepat di depan pintu masuk lapangan, sehingga memudahkan keluar-masuk tanpa harus berjalan jauh. Selain itu, area parkir juga dilengkapi dengan sistem CCTV untuk meningkatkan keamanan, sehingga kendaraan Anda dapat terpantau dengan baik selama berada di area kami.", textAlign: TextAlign.justify),
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