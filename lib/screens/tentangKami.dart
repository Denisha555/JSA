import 'package:flutter/material.dart';

// Halaman Tentang Kami
class HalamanTentangKami extends StatelessWidget {
  const HalamanTentangKami({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Text(
            "Tentang Kami",
            style: TextStyle(
              color: Colors.black,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(),
    );
  }
}