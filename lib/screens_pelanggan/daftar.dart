import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';
import 'package:flutter_application_1/services/firestore_service.dart';

class HalamanDaftar extends StatefulWidget {
  const HalamanDaftar({super.key});

  @override
  State<HalamanDaftar> createState() => _HalamanDaftarState();
}

class _HalamanDaftarState extends State<HalamanDaftar> {
  bool _obscureText = true;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String? errorTextUsername;
  String? errorTextPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // utama
        child: Center(
          child: Column(
            children: [
              // gambar
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Image.asset(
                  'assets/image/LogoJSA.jpg',
                  width: 300,
                  height: 300,
                ),
              ),
              // username
              Padding(
                padding: const EdgeInsets.only(
                  top: 20.0,
                  right: 30.0,
                  left: 30.0,
                ),
                child: TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    labelText: "Username",
                    errorText: errorTextUsername,
                  ),
                  onChanged: (value) {
                    setState(() {
                      errorTextUsername = null;
                    });
                  },
                ),
              ),
              // password
              Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  right: 30.0,
                  left: 30.0,
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    labelText: "Password",
                    errorText: errorTextPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      errorTextPassword = null;
                    });
                  },
                ),
              ),
              // button daftar
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Validasi input username dan password
                    if (usernameController.text.isEmpty) {
                      setState(() {
                        errorTextUsername = "Username tidak boleh kosong";
                      });
                    } else if (passwordController.text.isEmpty) {
                      setState(() {
                        errorTextPassword = "Password tidak boleh kosong";
                      });
                    } else if (passwordController.text.length < 6) {
                      setState(() {
                        errorTextPassword = "Password minimal 6 karakter";
                      });
                    } else {
                      // Menghapus pesan error jika input valid
                      setState(() {
                        errorTextUsername = null;
                        errorTextPassword = null;
                      });

                      // Mengecek apakah username sudah terdaftar
                      FirebaseService()
                          .checkUser(usernameController.text)
                          .then((registed) {
                            if (registed) {
                              // Jika username sudah terdaftar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Username sudah terdaftar.'),
                                ),
                              );
                            } else {
                              // Jika username belum terdaftar
                              FirebaseService()
                                  .addUser(
                                    usernameController.text,
                                    passwordController.text,
                                  )
                                  .then((_) {
                                    // Setelah user berhasil ditambahkan, arahkan ke halaman utama
                                    Navigator.pop(
                                      context,
                                    ); 
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const PilihHalamanPelanggan(),
                                      ),
                                    );
                                  })
                                  .catchError((e) {
                                    // Menangani error saat penambahan user
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Gagal menambahkan user: $e',
                                        ),
                                      ),
                                    );
                                  });
                            }
                          })
                          .catchError((e) {
                            // Menangani error saat pengecekan username
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Terjadi kesalahan: $e')),
                            );
                          });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(42, 92, 170, 1),
                    minimumSize: const Size(300, 50),
                  ),
                  child: const Text(
                    "Daftar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
