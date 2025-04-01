import 'package:flutter/material.dart';

// Halaman Aktivitas
class HalamanAktivitas extends StatelessWidget {
  const HalamanAktivitas({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Aktivitas"),
          bottom: TabBar(tabs: [Tab(text: "Data"), Tab(text: "Pengaturan")]),
        ),
        body: Padding(
          padding: EdgeInsets.all(20),
          child: ListView(children: [ExpansionTile(title: Text("Data"))]),
        ),
      ),
    );
  }
}
