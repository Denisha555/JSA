import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

class SewaRaket extends StatelessWidget {
  const SewaRaket({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sewa Raket'),
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
                Image.asset("assets/image/SewaRaket1.jpeg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
                Image.asset("assets/image/SewaRaket2.jpeg", fit: BoxFit.cover, width: double.infinity, height: MediaQuery.of(context).size.width,),
              ],
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text("Detail Fasilitas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("Lupa membawa raket? Tidak perlu khawatir, kami menyediakan layanan penyewaan raket dengan harga yang sangat terjangkau, yaitu hanya Rp15.000 per pcs. Menariknya, sistem sewa di sini tidak dihitung per jam, sehingga Anda bebas menggunakan raket selama sesi bermain berlangsung tanpa perlu memikirkan tambahan biaya. Dengan layanan ini, Anda tetap bisa menikmati permainan dengan nyaman dan fleksibel meskipun tanpa membawa perlengkapan pribadi.", textAlign: TextAlign.justify),
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