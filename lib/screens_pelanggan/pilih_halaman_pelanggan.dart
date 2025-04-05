import 'package:flutter/material.dart';
import 'halaman_utama_pelanggan.dart';
import 'aktivitas.dart';
import 'profile.dart';


final List<Widget> page = [
  HalamanUtamaPelanggan(),
  HalamanAktivitas(),
  HalamanProfil(),
];

class PilihHalamanPelanggan extends StatefulWidget {
  const PilihHalamanPelanggan({super.key});

  @override
  State<PilihHalamanPelanggan> createState() => _PilihHalamanPelangganState();
}

class _PilihHalamanPelangganState extends State<PilihHalamanPelanggan> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    switch (index) {
      case 0: 
        setState(() {
          _selectedIndex = 0;
        });
      case 1:
        setState(() {
          _selectedIndex = 1;
        });
      case 2: 
        setState(() {
          _selectedIndex = 2;
        });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: page[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex, 
      onTap: _onItemTapped, 
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Aktivitas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    ),
    );
  }
}