import 'package:flutter/material.dart';
import 'halaman_utama_pelanggan.dart';
import 'aktivitas.dart';

class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
    );
  }
}