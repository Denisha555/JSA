import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/screens_pelanggan/tentang_kami/kantin.dart';
import 'package:flutter_application_1/screens_pelanggan/tentang_kami/lapangan.dart';
import 'package:flutter_application_1/screens_pelanggan/tentang_kami/musholla.dart';
import 'package:flutter_application_1/screens_pelanggan/tentang_kami/parkiran.dart';
import 'package:flutter_application_1/screens_pelanggan/tentang_kami/sewa_raket.dart';
import 'package:flutter_application_1/screens_pelanggan/tentang_kami/toilet.dart';
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
          desiredAccuracy:
              LocationAccuracy.reduced, // Gunakan akurasi lebih rendah
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error membuka link: $e')));
      }
    }
  }

  void _bukaGoogleMaps() async {
    try {
      final String origin =
          _lokasiPengguna != null
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
        children: [
          Container(
            color: primaryColor,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Center(
                child: Text(
                  "Jump, smash, and win! Rasakan serunya main badminton di Jump Smash Arena—lapangan kece, suasana oke!",
                  style: TextStyle(fontSize: 15, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business_outlined, color: primaryColor),
                    SizedBox(width: 8),
                    Text(
                      "Galeri Fasilitas",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Lapangan(),
                              ),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(255, 217, 217, 217),
                                width: 1.5,
                              ),
                              image: DecorationImage(
                                image: AssetImage('assets/image/Lapangan1.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text("Lapangan"),
                      ],
                    ),
                    SizedBox(width: 9),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SewaRaket(),
                              ),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(255, 217, 217, 217),
                                width: 1.5,
                              ),
                              image: DecorationImage(
                                image: AssetImage('assets/image/SewaRaket1.jpeg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text("Sewa Raket"),
                      ],
                    ),
                    SizedBox(width: 9),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Parkiran(),
                              ),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(255, 217, 217, 217),
                                width: 1.5,
                              ),
                              image: DecorationImage(
                                image: AssetImage('assets/image/Parkiran1.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text("Parkiran"),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Kantin(),
                              ),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(255, 217, 217, 217),
                                width: 1.5,
                              ),
                              image: DecorationImage(
                                image: AssetImage('assets/image/Kantin1.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text("Kantin"),
                      ],
                    ),
                    SizedBox(width: 9),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Musholla(),
                              ),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(255, 217, 217, 217),
                                width: 1.5,
                              ),
                              image: DecorationImage(
                                image: AssetImage('assets/image/Musholla1.jpeg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text("Musholla"),
                      ],
                    ),
                    SizedBox(width: 9),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Toilet(),
                              ),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(255, 217, 217, 217),
                                width: 1.5,
                              ),
                              image: DecorationImage(
                                image: AssetImage('assets/image/Toilet1.jpeg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text("Toilet"),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.location_on, color: primaryColor),
                    SizedBox(width: 8),
                    Text(
                      "Lokasi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
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
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                              tileProvider: NetworkTileProvider(),
                              errorImage:
                                  Image.asset(
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color.fromARGB(255, 228, 243, 255),
                      border: Border.all(
                        color: const Color.fromARGB(255, 195, 228, 255),
                        width: 1.5,
                      ),
                    ),
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Jump Smash Arena",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            'Jln. Parit Haji Husein 1, Gg. Sawit No.10, Bangka Belitung Laut, Kec. Pontianak Tenggara, Kota Pontianak, Kalimantan Barat 78124',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 97, 97, 97),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.access_time, color: primaryColor),
                    SizedBox(width: 8),
                    const Text(
                      'Jam Operasional',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color.fromARGB(255, 241, 241, 241),
                    border: Border.all(
                      color: const Color.fromARGB(255, 217, 217, 217),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Senin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '07.30 - 23.00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Selasa',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '07.30 - 23.00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Rabu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '07.30 - 23.00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Kamis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '07.30 - 23.00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Jumat',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '07.30 - 23.00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Sabtu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '07.30 - 23.00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Minggu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '07.30 - 23.00',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note : Jam operasional dapat berubah selama hari libur, harap hubungi kami untuk informasi lebih lanjut.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          241,
                          241,
                          241,
                        ),
                      ),
                      icon: Image.asset(
                        'assets/image/Whatsapp.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text(
                        "WhatsApp",
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        _bukaLink('https://wa.me/6281299931908');
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          241,
                          241,
                          241,
                        ),
                      ),
                      icon: Image.asset(
                        'assets/image/Instagram.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text(
                        "Instagram",
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        _bukaLink(
                          'https://www.instagram.com/jumpsmasharena?igsh=MWRpcG53YmRnYWRubA==',
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
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
