import 'package:flutter/material.dart';
import 'halaman_utama_pelanggan.dart';
import 'aktivitas.dart';
import 'profile.dart';

class PilihHalamanPelanggan extends StatefulWidget {
  final int selectedIndex;

  const PilihHalamanPelanggan({super.key, this.selectedIndex = 0});

  @override
  State<PilihHalamanPelanggan> createState() => _PilihHalamanPelangganState();
}

class _PilihHalamanPelangganState extends State<PilihHalamanPelanggan> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  // Daftar halaman dengan type safety
  static const List<Widget> _pages = <Widget>[
    HalamanUtamaPelanggan(),
    HalamanAktivitas(),
    HalamanProfil(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
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
            label: 'Aktivitas',
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
