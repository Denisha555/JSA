import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'halaman_utama_pelanggan.dart';
import 'profile.dart';

class Riwayat {
  final String tanggal;
  final String keterangan;

  Riwayat({required this.tanggal, required this.keterangan});
}

List<Riwayat> riwayats = [
  Riwayat(tanggal: "2022-01-01", keterangan: "Lapangan Berhasil Terbooking"),
  Riwayat(tanggal: "2022-01-02", keterangan: "Lapangan Berhasil Terbooking"),
  Riwayat(tanggal: "2022-01-03", keterangan: "Lapangan Berhasil Terbooking"),
];

class Terjadwal {
  final String tanggal;
  final String jam;
  final String lapangan;

  Terjadwal({required this.tanggal, required this.jam, required this.lapangan});
}

List<Terjadwal> terjadwals = [
  Terjadwal(tanggal: "2022-01-01", jam: "08:00", lapangan: "Lapangan 1"),
  Terjadwal(tanggal: "2022-01-02", jam: "10:00", lapangan: "Lapangan 2"),
];

// Halaman Aktivitas
class HalamanAktivitas extends StatefulWidget {
  const HalamanAktivitas({super.key});

  @override
  State<HalamanAktivitas> createState() => _HalamanAktivitasState();
}

class _HalamanAktivitasState extends State<HalamanAktivitas> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Aktivitas"),
          bottom: TabBar(tabs: [Tab(text: "Riwayat"), Tab(text: "Terjadwal")]),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: ListView.builder(
                itemCount:
                    riwayats.length, 
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(riwayats[index].tanggal),
                      subtitle: Text(riwayats[index].keterangan),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: ListView.builder(
                itemCount:
                    terjadwals.length, 
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(terjadwals[index].tanggal),
                      subtitle: Text(terjadwals[index].jam),
                      trailing: Text(terjadwals[index].lapangan),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
