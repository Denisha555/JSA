import 'package:flutter/material.dart';
import 'halaman_utama_user.dart';

class HalamanMasuk extends StatefulWidget {
  const HalamanMasuk({super.key});

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk> {
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
                      borderRadius: BorderRadius.circular(30),
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
                      borderRadius: BorderRadius.circular(30),
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
              // tombol masuk
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (usernameController.text.isEmpty) {
                        errorTextUsername = "Username tidak boleh kosong";
                      } else if (passwordController.text.isEmpty) {
                        errorTextPassword = "Password tidak boleh kosong";
                      } else {
                        errorTextUsername = null;
                        errorTextPassword = null;
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HalamanUtamaUser(),
                          ),
                        );
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(133, 170, 211, 1),
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text(
                    "Masuk",
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