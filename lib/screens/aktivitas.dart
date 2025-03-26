import 'package:flutter/material.dart';

// Halaman Aktivitas
class HalamanAktivitas extends StatelessWidget {
  const HalamanAktivitas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Text(
            "Aktivitas",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}