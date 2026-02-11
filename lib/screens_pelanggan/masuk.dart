import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/screen_owner/halaman_utama_owner.dart';
import 'package:flutter_application_1/screens_pelanggan/lupa_password.dart';
import 'package:flutter_application_1/services/notification/onesignal_add_notification.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/user/firebase_add_user.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/screens_admin/halaman_utama_admin.dart';
import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';


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
    // Reset error states
    setState(() {
      errorTextUsername = null;
      errorTextPassword = null;
    });

    // Validasi input
    if (usernameController.text.isEmpty) {
      setState(() {
        errorTextUsername = "Username tidak boleh kosong";
      });
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        errorTextPassword = "Password tidak boleh kosong";
      });
      return;
    }

    if (passwordController.text.length < 6) {
      setState(() {
        errorTextPassword = "Password minimal 6 karakter";
      });
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug log
      debugPrint('Starting login process for: ${usernameController.text}');

      // Handle admin login
      if (usernameController.text == "admin_1" &&
          passwordController.text == "admin_1") {
        await _handleAdminLogin();
        return;
      }

      // Handle owner login
      if (usernameController.text == "owner_1" &&
          passwordController.text == "owner_1") {
        await _handleOwnerLogin();
        return;
      }

      // Handle customer login
      await _handleCustomerLogin();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAdminLogin() async {
    try {
      bool registered = await FirebaseCheckUser().checkExistence(
        'username',
        usernameController.text,
      );

      if (!registered) {
        await FirebaseAddUser().addUser(
          userName: usernameController.text,
          password: passwordController.text,
          role: 'admin',
        );
        debugPrint('Admin account created');
      }

      // Save to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', usernameController.text);
      
      if (!kIsWeb) {
        var id = await OneSignal.User.getOnesignalId();
      await prefs.setString('admin_id', id!);
        OneSignal.User.addTagWithKey("role", "admin");
      await OneSignalAddNotification().addNotification(id);
      }
    
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HalamanUtamaAdmin()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal login admin: $e');
    }
  }

  Future<void> _handleOwnerLogin() async {
    try {
      bool registered = await FirebaseCheckUser().checkExistence(
        'username',
        usernameController.text,
      );

      if (!registered) {
        await FirebaseAddUser().addUser(
          userName: usernameController.text,
          password: passwordController.text,
          role: 'owner',
        );
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', usernameController.text);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HalamanUtamaOwner()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal login owner: $e');
    }
  }

  Future<void> _handleCustomerLogin() async {
    try {
      // Check if user is registered
      bool registered = await FirebaseCheckUser().checkExistence(
        'username',
        usernameController.text,
      );

      if (!registered) {
        if (!mounted) return;
        showErrorSnackBar(
          context,
          'Username belum terdaftar, silahkan daftar terlebih dahulu.',
        );

        return;
      }

      // Check password
      bool validPassword = await FirebaseCheckUser().checkPassword(
        usernameController.text,
        hashPassword(passwordController.text),
      );

      if (!validPassword) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Password tidak sesuai.');
        return;
      }

      // Save to shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', usernameController.text);

      if (mounted) {
        // Add a small delay to ensure all async operations complete
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const PilihHalamanPelanggan(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Customer login error: $e');
      if (!mounted) return;
        showErrorSnackBar(context, 'Gagal login: $e');
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
                          right: screenWidth * 0.1,
                          left: screenWidth * 0.1,
                        ),
                        child: Image.asset(
                          'assets/image/LogoJSA.jpg',
                          width: 150,
                          height: 150,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
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
                            disabledBackgroundColor: primaryColor.withValues(
                              alpha: 0.6,
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

                      // Debug info (remove in production)
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            "Sedang memproses login...",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        
                      GestureDetector(
                        onTap: () {
                          // Navigator.push(context, MaterialPageRoute(
                          //   builder: (context) => HalamanLupaPassword(),
                          // ));
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            "Lupa password?",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      )
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
