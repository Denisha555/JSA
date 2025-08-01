import 'profile.dart';
import 'aktivitas.dart';
import 'halaman_utama_pelanggan.dart';
import 'package:flutter/material.dart';


class PilihHalamanPelanggan extends StatefulWidget {
  final int selectedIndex;

  const PilihHalamanPelanggan({super.key, this.selectedIndex = 0});

  @override
  State<PilihHalamanPelanggan> createState() => _PilihHalamanPelangganState();
}

class _PilihHalamanPelangganState extends State<PilihHalamanPelanggan> {
  int _currentIndex = 0;
  Key _aktivitasKey = UniqueKey(); // ← disimpan di level state

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const HalamanUtamaPelanggan();
      case 1:
        return HalamanAktivitas(key: _aktivitasKey); 
      case 2:
        return const HalamanProfil();
      default:
        return const HalamanUtamaPelanggan();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 1) {
        _aktivitasKey = UniqueKey(); // ← update state
      }
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
