import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/screens_admin/halaman_utama_admin.dart';
import 'package:flutter_application_1/screen_owner/halaman_utama_owner.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class HalamanMasuk extends StatefulWidget {
  const HalamanMasuk({super.key});

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isLoading = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String? errorTextUsername;
  String? errorTextPassword;

  // Menambahkan animasi
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString(); 
  }

  void _login() async {
    // Validasi input
    if (usernameController.text.isEmpty) {
      setState(() {
        errorTextUsername = "Username tidak boleh kosong";
      });
      return;
    } else if (passwordController.text.isEmpty) {
      setState(() {
        errorTextPassword = "Password tidak boleh kosong";
      });
      return;
    } else if (passwordController.text.length < 6) {
      setState(() {
        errorTextPassword = "Password minimal 6 karakter";
      });
      return;
    } else {
      setState(() {
        errorTextUsername = null;
        errorTextPassword = null;
        _isLoading = true;
      });
    }

    try {
      // Jika username dan password adalah admin
      if (usernameController.text == "admin_1" &&
          passwordController.text == "admin_1") {
        try {
          bool registered = await FirebaseService().checkUser(
            usernameController.text,
          );
          // jika akun sudah ada
          if (registered) {
            if (mounted) {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanUtamaAdmin(),
                ),
              );
            }
            // jika akun belum ada tambah data ke database
          } else {
            await FirebaseService().addAdminOwner(
              usernameController.text,
              passwordController.text,
            );
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanUtamaAdmin(),
                ),
              );
            }
          }
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('username', usernameController.text);
          return;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Terjadi kesalahan: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      // jika username dan password adalah owner
      if (usernameController.text == "owner_1" &&
          passwordController.text == "owner_1") {
        try {
          bool registered = await FirebaseService().checkUser(
            usernameController.text,
          );
          // jika sudah ada akun
          if (registered) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanUtamaOwner(),
                ),
              );
            }
            // jika belum ada akun tambah data ke database
          } else {
            await FirebaseService().addAdminOwner(
              usernameController.text,
              passwordController.text,
            );
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanUtamaOwner(),
                ),
              );
            }
          }
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('username', usernameController.text);
          return;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Terjadi kesalahan: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      // Pengecekan login untuk pelanggan
      bool registered = await FirebaseService().checkUser(
        usernameController.text,
      );
      debugPrint('Registered: $registered');

      try {
        if (registered) {
          bool valid = await FirebaseService().checkPassword(
            usernameController.text,
            hashPassword(passwordController.text),
          );

          // jika username dan password benar
          if (mounted) {
            if (valid) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('username', usernameController.text);

              if (!mounted) return;
              
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PilihHalamanPelanggan(),
                ),
              );
              // jika username dan password salah
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password tidak sesuai.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username belum terdaftar, silahkan daftar terlebih dahulu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Padding(
                        padding: EdgeInsets.only(
                          top: screenHeight * 0.01,
                          bottom: screenHeight * 0.03,
                        ),
                        child: Image.asset(
                          'assets/image/LogoJSA.jpg',
                          width: 150, height: 150
                        ),
                      ),

                      // Judul login
                      const Padding(
                        padding: EdgeInsets.only(bottom: 30.0),
                        child: Text(
                          "Masuk ke Akun Anda",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),

                      // Username field
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: primaryColor,
                              width: 2.0,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: primaryColor,
                          ),
                          labelText: "Username",
                          labelStyle: const TextStyle(color: Colors.grey),
                          errorText: errorTextUsername,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15.0,
                            horizontal: 20.0,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            errorTextUsername = null;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // Password field
                      TextField(
                        controller: passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.0
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: primaryColor,
                              width: 2.0,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: primaryColor,
                          ),
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Colors.grey),
                          errorText: errorTextPassword,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15.0,
                            horizontal: 20.0,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
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
                        onSubmitted: (_) => _login(),
                      ),

                      const SizedBox(height: 30),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            disabledBackgroundColor: primaryColor.withOpacity(
                              0.6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                            elevation: 3,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Text(
                                    "Masuk",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
