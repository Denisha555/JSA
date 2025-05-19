import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screens_pelanggan/member.dart';
import 'package:flutter_application_1/main.dart';

class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  String? username;
  String? fotoPath;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? ' ';
      fotoPath = prefs.getString('fotoProfil');
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fotoProfil', picked.path);
      setState(() {
        fotoPath = picked.path;
      });
    }
  }

  void _showEditNamaDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditNama())).then((_) {
      // Reload data setelah edit nama selesai
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              title: Text('Pusat Akun'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PusatAkun()),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Keluar'),
              onTap: () {
                // Tambahkan aksi logout jika perlu
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(title: Text('Profil')),
      body: username == null 
      ? CircularProgressIndicator()
      : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 30,
                backgroundImage: fotoPath != null
                    ? FileImage(File(fotoPath!))
                    : AssetImage('assets/avatar.jpg') as ImageProvider,
              ),
            ),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(username!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('2.450 Poin'),
            ]),
          ]),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('25 Booking', style: TextStyle(fontSize: 16)),
                  Text('2.450 Poin', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text('👑 Member\n@seabar dalam 8 hari', style: TextStyle(fontSize: 14)),
          SizedBox(height: 20),
          Text('Aktivitas', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            leading: Icon(Icons.sports_soccer),
            title: Text('Booking Lapangan - Lapangan 3'),
            subtitle: Text('2 hari yang lalu'),
          ),
          Divider(),
          SizedBox(height: 10),
          Text('Progres', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2.450', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {},
                child: Text('Riwayat Poin'),
              )
            ],
          ),
          SizedBox(height: 5),
          Text('Poin terkumpul bulan ini: +450'),
          SizedBox(height: 20),
          ListTile(
            title: Text("Ubah Nama Pengguna"),
            trailing: Icon(Icons.edit),
            onTap: _showEditNamaDialog,
          ),
        ]),
      ),
    );
  }
}

// ===================== PUSAT AKUN =====================
class PusatAkun extends StatelessWidget {
  const PusatAkun({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pusat Akun")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Profil"),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit),
                      title: Text("Nama Pengguna"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditNama()),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.image),
                      title: Text("Foto Profil"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UbahFoto()),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Kata Sandi dan Keamanan"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UbahPassword()),
            ),
          )
        ]),
      ),
    );
  }
}

// ===================== EDIT NAMA =====================
class EditNama extends StatefulWidget {
  const EditNama({super.key});
  @override
  State<EditNama> createState() => _EditNamaState();
}

class _EditNamaState extends State<EditNama> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _simpanNama() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('namaPengguna', _controller.text);
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _controller.text = prefs.getString('namaPengguna') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit nama pengguna")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: "Nama Pengguna"),
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _simpanNama, child: Text("Konfirmasi"))
        ]),
      ),
    );
  }
}

// ===================== UBAH FOTO =====================
class UbahFoto extends StatefulWidget {
  const UbahFoto({super.key});
  @override
  State<UbahFoto> createState() => _UbahFotoState();
}

class _UbahFotoState extends State<UbahFoto> {
  String? _fotoPath;

  Future<void> _pilihFoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fotoProfil', picked.path);
      setState(() => _fotoPath = picked.path);
    }
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() => _fotoPath = prefs.getString('fotoProfil'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ubah Foto Profil")),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _fotoPath != null
              ? CircleAvatar(radius: 60, backgroundImage: FileImage(File(_fotoPath!)))
              : Icon(Icons.account_circle, size: 120),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _pilihFoto, child: Text("Pilih Foto Baru")),
        ]),
      ),
    );
  }
}

// ===================== UBAH PASSWORD =====================
class UbahPassword extends StatefulWidget {
  const UbahPassword({super.key});
  @override
  State<UbahPassword> createState() => _UbahPasswordState();
}

class _UbahPasswordState extends State<UbahPassword> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _ulangPassword = TextEditingController();

  void _konfirmasi() {
    if (_password.text == _ulangPassword.text && _password.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kata sandi berhasil diperbarui!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kata sandi tidak cocok atau kosong!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ubah Kata Sandi")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: "Kata Sandi Baru"),
          ),
          TextField(
            controller: _ulangPassword,
            obscureText: true,
            decoration: InputDecoration(labelText: "Ulangi Kata Sandi"),
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _konfirmasi, child: Text("Konfirmasi"))
        ]),
      ),
    );
  }
}