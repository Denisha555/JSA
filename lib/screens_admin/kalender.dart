import 'package:flutter/material.dart';

class HalamanKalender extends StatelessWidget {
  const HalamanKalender({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kalender"),),
      body: Center(
        child: Text("Halaman Kalender"),
      ),
    );
  }
}