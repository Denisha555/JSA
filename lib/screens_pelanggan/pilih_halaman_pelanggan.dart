import 'package:flutter/material.dart';
import 'halaman_utama_pelanggan.dart';
import 'aktivitas.dart';
import 'profile.dart';

class PilihHalamanPelanggan extends StatefulWidget {
  const PilihHalamanPelanggan({super.key});

  @override
  State<PilihHalamanPelanggan> createState() => _PilihHalamanPelangganState();
}

class _PilihHalamanPelangganState extends State<PilihHalamanPelanggan> {
  int _selectedIndex = 0;
  
  // Daftar halaman dengan type safety
  static const List<Widget> _pages = <Widget>[
    HalamanUtamaPelanggan(),
    HalamanAktivitas(),
    HalamanProfil(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, 
        unselectedItemColor: Colors.grey, 
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}