import 'package:flutter/material.dart';

class HalamanUtamaOwner extends StatelessWidget {
  const HalamanUtamaOwner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
      ),
      body: Center(child: Text("Halaman Utama Owner"),),
    );
  }
}