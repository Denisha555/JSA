import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

// Halaman Tentang Kami
class HalamanTentangKami extends StatefulWidget {
  const HalamanTentangKami({super.key});

  @override
  State<HalamanTentangKami> createState() => _HalamanTentangKamiState();
}

class _HalamanTentangKamiState extends State<HalamanTentangKami> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tentang Kami")
      )
    );
  }
}
