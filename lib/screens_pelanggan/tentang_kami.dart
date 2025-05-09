import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class HalamanTentangKami extends StatelessWidget {
   HalamanTentangKami({super.key});

  // Ganti ini dengan lokasi asli kamu
  final LatLng _lokasiKita = LatLng(-0.05687, 109.35996); 

  void _bukaLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Tidak dapat membuka: $url';
    }
  }

  void _bukaGoogleMaps() async {
    final Uri mapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${_lokasiKita.latitude},${_lokasiKita.longitude}');
    if (!await launchUrl(mapsUrl, mode: LaunchMode.externalApplication)) {
      throw 'Tidak bisa membuka Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tentang Kami"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/image/TentangKami.png',
                  height: 100,
                ),
                const SizedBox(height: 12),
                const Text(
                  'JUMP SMASH ARENA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jump, smash, and win! Rasakan serunya main badminton di Jump SMASH Arena—lapangan kece, suasana oke!',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _lokasiKita,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _lokasiKita,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _bukaGoogleMaps,
            child: Row(
              children: const [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jln. Parit Haji Husein 1,Gg. Sawit No.10, Bangka Belitung Laut, Kec. Pontianak Tenggara, Kota Pontianak, Kalimantan Barat 78124\n\n(Tap untuk petunjuk arah)',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Jam Operasional',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const JamRow(hari: 'Senin', jam: '07.00 - 23.00'),
          const JamRow(hari: 'Selasa', jam: '07.00 - 23.00'),
          const JamRow(hari: 'Rabu', jam: '07.00 - 23.00'),
          const JamRow(hari: 'Kamis', jam: '07.00 - 23.00'),
          const JamRow(hari: 'Jumat', jam: '07.00 - 23.00'),
          const JamRow(hari: 'Sabtu', jam: '07.00 - 23.00'),
          const JamRow(hari: 'Minggu', jam: '07.00 - 23.00'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                label: const Text("WhatsApp", style: TextStyle(color: Colors.white),),
                onPressed: () {
                  _bukaLink('https://wa.me/6281299931908'); 
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 64, 156),
                ),
                label: const Text("Instagram", style: TextStyle(color: Colors.white),),
                onPressed: () {
                  _bukaLink('https://www.instagram.com/jumpsmasharena?igsh=MWRpcG53YmRnYWRubA=='); 
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class JamRow extends StatelessWidget {
  final String hari;
  final String jam;

  const JamRow({super.key, required this.hari, required this.jam});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(hari),
          Text(jam),
        ],
      ),
    );
  }
}