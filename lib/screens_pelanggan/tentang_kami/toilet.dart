import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;

class Toilet extends StatefulWidget {
  const Toilet({super.key});

  @override
  State<Toilet> createState() => _ToiletState();
}

class _ToiletState extends State<Toilet> {
  int activeIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Toilet")),
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
                    Image.asset(
                      "assets/image/Toilet1.jpeg",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width,
                    ),
                    Image.asset(
                      "assets/image/Toilet2.jpg",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width,
                    ),
                  ],
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [0, 1].asMap().entries.map((entry) {
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
                  ),
                )
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
                    "Kami menyediakan empat unit toilet yang terletak di bagian pojok kiri dari arah pintu masuk, sehingga mudah diakses oleh pengunjung. Fasilitas ini dibagi secara terpisah, yaitu dua toilet untuk laki-laki dan dua toilet untuk perempuan, guna menjaga kenyamanan dan privasi bersama selama berada di area lapangan. Dengan penataan yang rapi dan kebersihan yang terjaga, kami berupaya memastikan kebutuhan dasar pengunjung dapat terpenuhi dengan baik, sehingga pengalaman bermain tetap nyaman dan menyenangkan.",
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
