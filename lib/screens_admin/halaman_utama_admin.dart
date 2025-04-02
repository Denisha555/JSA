import 'package:flutter/material.dart';

class HalamanUtamaAdmin extends StatelessWidget {
  const HalamanUtamaAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        
      ),
      body: const Center(
        child: Text('Selamat Datang di Halaman Utama Admin'),
      ),
    );
  }
}