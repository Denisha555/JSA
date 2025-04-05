import 'package:flutter/material.dart';

class HalamanKalender extends StatefulWidget {
  const HalamanKalender({super.key});

  @override
  State<HalamanKalender> createState() => _HalamanKalenderState();
}

class _HalamanKalenderState extends State<HalamanKalender> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
      ),
    );
  }
}