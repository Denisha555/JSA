import 'package:flutter/material.dart';

class HalamanJadwal extends StatefulWidget {
  const HalamanJadwal({super.key});

  @override
  State<HalamanJadwal> createState() => _HalamanJadwalState();
}

class _HalamanJadwalState extends State<HalamanJadwal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal'),
      ),
    );
  }
}