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
  
  // Key untuk force rebuild halaman Aktivitas
  Key _aktivitasKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  // Method untuk mendapatkan halaman berdasarkan index
  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const HalamanUtamaPelanggan();
      case 1:
        // Generate key baru setiap kali tab Aktivitas dibuka
        return HalamanAktivitas();
      case 2:
        return const HalamanProfil();
      default:
        return const HalamanUtamaPelanggan();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      // Jika pindah ke tab Aktivitas, generate key baru untuk force refresh
      if (index == 1) {
        _aktivitasKey = UniqueKey();
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gunakan body langsung tanpa IndexedStack
      body: _getCurrentPage(),
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