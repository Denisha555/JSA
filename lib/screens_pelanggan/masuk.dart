// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';
// import 'package:flutter_application_1/services/firestore_service.dart';
// import 'package:flutter_application_1/screens_admin/halaman_utama_admin.dart';

// class HalamanMasuk extends StatefulWidget {
//   const HalamanMasuk({super.key});

//   @override
//   State<HalamanMasuk> createState() => _HalamanMasukState();
// }

// class _HalamanMasukState extends State<HalamanMasuk> {
//   bool _obscureText = true;
//   TextEditingController usernameController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//   String? errorTextUsername;
//   String? errorTextPassword;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         // utama
//         child: Center(
//           child: Column(
//             children: [
//               // gambar
//               Padding(
//                 padding: EdgeInsets.only(top: 20.0),
//                 child: Image.asset(
//                   'assets/image/LogoJSA.jpg',
//                   width: 300,
//                   height: 300,
//                 ),
//               ),
//               // username
//               Padding(
//                 padding: const EdgeInsets.only(
//                   top: 20.0,
//                   right: 30.0,
//                   left: 30.0,
//                 ),
//                 child: TextField(
//                   controller: usernameController,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     labelText: "Username",
//                     errorText: errorTextUsername,
//                   ),
//                   onChanged: (value) {
//                     setState(() {
//                       errorTextUsername = null;
//                     });
//                   },
//                 ),
//               ),
//               // password
//               Padding(
//                 padding: const EdgeInsets.only(
//                   top: 10.0,
//                   right: 30.0,
//                   left: 30.0,
//                 ),
//                 child: TextField(
//                   controller: passwordController,
//                   obscureText: _obscureText,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     labelText: "Password",
//                     errorText: errorTextPassword,
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureText ? Icons.visibility : Icons.visibility_off,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _obscureText = !_obscureText;
//                         });
//                       },
//                     ),
//                   ),
//                   onChanged: (value) {
//                     setState(() {
//                       errorTextPassword = null;
//                     });
//                   },
//                 ),
//               ),
//               // tombol masuk
//               Padding(
//                 padding: const EdgeInsets.only(top: 20),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Validasi input
//                     if (usernameController.text.isEmpty) {
//                       setState(() {
//                         errorTextUsername = "Username tidak boleh kosong";
//                       });
//                       return;
//                     } else if (passwordController.text.isEmpty) {
//                       setState(() {
//                         errorTextPassword = "Password tidak boleh kosong";
//                       });
//                       return;
//                     } else {
//                       setState(() {
//                         errorTextUsername = null;
//                         errorTextPassword = null;
//                       });
//                     }

//                     // Jika username dan password adalah admin
//                     if (usernameController.text == "admin_1" && passwordController.text == "admin_1") {
//                       FirebaseService().checkUser(usernameController.text).then((registered) {
//                         if (registered) {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const HalamanUtamaAdmin(),
//                             ),
//                           );
//                           return;
//                         } else {
//                           FirebaseService().addUser(usernameController.text, passwordController.text).then((
//                             _,
//                           ) {
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const HalamanUtamaAdmin(),
//                               ),
//                             );
//                           });
//                         }
//                         return;
//                       });
//                     }
//                     // Pengecekan login untuk pelanggan
//                     FirebaseService()
//                         .checkPassword(usernameController.text, passwordController.text)
//                         .then((valid) {
//                           if (valid) {
//                             Navigator.pop(context);
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder:
//                                     (context) => const PilihHalamanPelanggan(),
//                               ),
//                             );
//                             return;
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text(
//                                   'Username atau password tidak sesuai.',
//                                 ),
//                               ),
//                             );
//                           }
//                         })
//                         .catchError((e) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(content: Text('Terjadi kesalahan: $e')),
//                           );
//                         });
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color.fromRGBO(42, 92, 170, 1),
//                     minimumSize: const Size(200, 50),
//                   ),
//                   child: const Text(
//                     "Masuk",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/screens_admin/halaman_utama_admin.dart';

// Konstanta warna untuk konsistensi
const Color primaryColor = Color.fromRGBO(42, 92, 170, 1);
const double borderRadius = 30.0;

class HalamanMasuk extends StatefulWidget {
  const HalamanMasuk({super.key});

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk> with SingleTickerProviderStateMixin {
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
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
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
    } else {
      setState(() {
        errorTextUsername = null;
        errorTextPassword = null;
        _isLoading = true;
      });
    }

    try {
      // Jika username dan password adalah admin
      if (usernameController.text == "admin_1" && passwordController.text == "admin_1") {
        try {
          bool registered = await FirebaseService().checkUser(usernameController.text);
          if (registered) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanUtamaAdmin(),
                ),
              );
            }
          } else {
            await FirebaseService().addUser(usernameController.text, passwordController.text);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HalamanUtamaAdmin(),
                ),
              );
            }
          }
          return;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Terjadi kesalahan: $e')),
            );
          }
        }
      }
    
      // Pengecekan login untuk pelanggan
      bool valid = await FirebaseService().checkPassword(usernameController.text, passwordController.text);
      
      if (mounted) {
        if (valid) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PilihHalamanPelanggan(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username atau password tidak sesuai.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                          width: screenWidth * 0.6,
                          height: screenWidth * 0.6,
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
                            color: primaryColor
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
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(color: primaryColor, width: 2.0),
                          ),
                          prefixIcon: const Icon(Icons.person, color: primaryColor),
                          labelText: "Username",
                          labelStyle: const TextStyle(color: Colors.grey),
                          errorText: errorTextUsername,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            errorTextUsername = null;
                          });
                        },
                      ),
                      
                      // Space between fields
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
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(color: primaryColor, width: 2.0),
                          ),
                          prefixIcon: const Icon(Icons.lock, color: primaryColor),
                          labelText: "Password",
                          labelStyle: const TextStyle(color: Colors.grey),
                          errorText: errorTextPassword,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
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
                      
                      // Space before button
                      const SizedBox(height: 30),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            disabledBackgroundColor: primaryColor.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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