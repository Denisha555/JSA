import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';


class HalamanTentangKami extends StatefulWidget {
  const HalamanTentangKami({super.key});

  @override
  State<HalamanTentangKami> createState() => _HalamanTentangKamiState();
}

class _HalamanTentangKamiState extends State<HalamanTentangKami> {
  final LatLng _lokasiArena = const LatLng(-0.05687, 109.35996);
  LatLng? _lokasiPengguna;
  late final MapController _mapController = MapController();
  final bool _isLoading = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    // Hanya dapatkan lokasi pengguna untuk Google Maps tanpa memindahkan peta
    _dapatkanLokasiPengguna();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Metode baru yang hanya mendapatkan lokasi pengguna tanpa memindahkan peta
  Future<void> _dapatkanLokasiPengguna() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Dapatkan lokasi hanya sekali untuk link Google Maps
      try {
        Position posisi = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.reduced, // Gunakan akurasi lebih rendah
          timeLimit: const Duration(seconds: 5), // Timeout lebih cepat
        );
        
        if (mounted) {
          setState(() {
            _lokasiPengguna = LatLng(posisi.latitude, posisi.longitude);
          });
        }
      } catch (e) {
        // Lewati error tanpa menampilkan pesan
      }
    } catch (e) {
      // Lewati error tanpa menampilkan pesan
    }
  }

  void _bukaLink(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Tidak dapat membuka: $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error membuka link: $e')),
        );
      }
    }
  }

  void _bukaGoogleMaps() async {
    try {
      final String origin = _lokasiPengguna != null 
          ? '${_lokasiPengguna!.latitude},${_lokasiPengguna!.longitude}' 
          : '';
      
      final Uri mapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=${_lokasiArena.latitude},${_lokasiArena.longitude}',
      );
      
      if (!await launchUrl(mapsUrl, mode: LaunchMode.externalApplication)) {
        throw 'Tidak bisa membuka Google Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error membuka Google Maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang Kami"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                // Use error handler for asset loading
                Image.asset(
                  'assets/image/LogoJSA.jpg',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'JUMP SMASH ARENA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jump, smash, and win! Rasakan serunya main badminton di Jump Smash Arena—lapangan kece, suasana oke!',
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
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _lokasiArena,
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: ~InteractiveFlag.doubleTapZoom,
                      ),
                      onMapReady: () {
                        setState(() {
                          _mapReady = true;
                        });
                        // Move to user location if available
                        if (_lokasiPengguna != null) {
                          _mapController.move(_lokasiPengguna!, 16);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                        tileProvider: NetworkTileProvider(),
                        errorImage: Image.asset(
                          'assets/image/map_placeholder.png',
                          fit: BoxFit.cover,
                        ).image,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _lokasiArena,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                          if (_lokasiPengguna != null)
                            Marker(
                              point: _lokasiPengguna!,
                              width: 30,
                              height: 30,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.white.withValues(alpha: 0.7),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
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
                    'Jln. Parit Haji Husein 1, Gg. Sawit No.10, Bangka Belitung Laut, Kec. Pontianak Tenggara, Kota Pontianak, Kalimantan Barat 78124',
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
                style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 42, 92, 170)),
                label: const Text("WhatsApp", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  _bukaLink('https://wa.me/6281299931908');
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 42, 92, 170),
                ),
                label: const Text("Instagram", style: TextStyle(color: Colors.white)),
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
        children: [Text(hari), Text(jam)],
      ),
    );
  }
}