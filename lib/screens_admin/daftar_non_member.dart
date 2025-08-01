import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/screens_admin/customers.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/user/firebase_add_user.dart';


class HalamanNonMemberAdmin extends StatefulWidget {
  const HalamanNonMemberAdmin({super.key});

  @override
  State<HalamanNonMemberAdmin> createState() => _HalamanNonMemberAdminState();
}

class _HalamanNonMemberAdminState extends State<HalamanNonMemberAdmin>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _obscureText2 = true;
  bool _isLoading = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController konfirmasiPasswordController = TextEditingController();
  TextEditingController namaController = TextEditingController();
  TextEditingController noTelpController = TextEditingController();
  TextEditingController clubController = TextEditingController();

  // Individual error texts for each field
  String? errorTextUsername;
  String? errorTextPassword;
  String? errorTextKonfirmasiPassword;
  String? errorTextNama;
  String? errorTextNoTelp;
  String? errorTextClub;

  // Animation controllers
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
    konfirmasiPasswordController.dispose();
    namaController.dispose();
    noTelpController.dispose();
    clubController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _daftar() async {
    // Clear all previous errors
    setState(() {
      errorTextUsername = null;
      errorTextPassword = null;
      errorTextKonfirmasiPassword = null;
      errorTextNama = null;
      errorTextNoTelp = null;
      errorTextClub = null;
    });

    bool hasError = false;

    // Validate all fields
    if (usernameController.text.isEmpty) {
      setState(() {
        errorTextUsername = "Username tidak boleh kosong";
      });
      hasError = true;
    }

    if (namaController.text.isEmpty) {
      setState(() {
        errorTextNama = "Nama lengkap tidak boleh kosong";
      });
      hasError = true;
    }

    if (noTelpController.text.isEmpty) {
      setState(() {
        errorTextNoTelp = "Nomor telepon tidak boleh kosong";
      });
      hasError = true;
    } else if (!RegExp(r'^[0-9]+$').hasMatch(noTelpController.text)) {
      setState(() {
        errorTextNoTelp = "Nomor telepon hanya diisi dengan angka";
      });
      hasError = true;
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        errorTextPassword = "Password tidak boleh kosong";
      });
      hasError = true;
    } else if (passwordController.text.length < 6) {
      setState(() {
        errorTextPassword = "Password minimal 6 karakter";
      });
      hasError = true;
    }

    if (konfirmasiPasswordController.text.isEmpty) {
      setState(() {
        errorTextKonfirmasiPassword = "Konfirmasi password tidak boleh kosong";
      });
      hasError = true;
    } else if (passwordController.text != konfirmasiPasswordController.text) {
      setState(() {
        errorTextKonfirmasiPassword = "Password tidak sama";
      });
      hasError = true;
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final username = usernameController.text;
      final password = passwordController.text;
      final nama = namaController.text;
      final club = clubController.text;
      final noTelp = noTelpController.text;

      final registed = await FirebaseCheckUser().checkExistence(
        'username',
        username,
      );
      if (registed) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Username sudah terdaftar');
        return;
      }

      final namaUsed = await FirebaseCheckUser().checkExistence('name', nama);
      if (namaUsed) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Nama sudah digunakan');
        return;
      }

      final clubUsed = await FirebaseCheckUser().checkExistence('club', club);
      if (clubUsed) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Club sudah digunakan');
        return;
      }

      final telpUsed = await FirebaseCheckUser().checkExistence(
        'phoneNumber',
        noTelp,
      );
      if (telpUsed) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Nomor telepon sudah digunakan');
        return;
      }

      // Check if username is already registered
      await FirebaseAddUser().addUser(
        userName: username,
        password: hashPassword(password),
        role: 'nonMember',
        name: nama,
        club: club,
        phoneNumber: noTelp,
      );

      if (!mounted) return;
      showSuccessSnackBar(context, 'Akun berhasil didaftarkan');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HalamanCustomers()),
      );
    } catch (e) {
      showErrorSnackBar(context, 'Terjadi kesalahan: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
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
        prefixIcon: Icon(prefixIcon, color: primaryColor),
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 20.0,
        ),
      ),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 20),
                      buildTextField(
                        controller: usernameController,
                        labelText: "Username",
                        prefixIcon: Icons.person,
                        errorText: errorTextUsername,
                        onChanged: (value) {
                          setState(() {
                            errorTextNoTelp = null;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: namaController,
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icons.person_outline,
                        errorText: errorTextNama,
                        onChanged: (value) {
                          setState(() {
                            errorTextNama = null;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: clubController,
                        labelText: 'Nama Club (tidak wajib)',
                        prefixIcon: Icons.groups,
                        errorText: errorTextClub,
                        onChanged: (value) {
                          setState(() {
                            errorTextClub = null;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: noTelpController,
                        labelText: 'Nomor Telepon',
                        prefixIcon: Icons.phone,
                        errorText: errorTextNoTelp,
                        onChanged: (value) {
                          setState(() {
                            errorTextNoTelp = null;
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
                        onSubmitted: (_) => _daftar(),
                      ),

                      const SizedBox(height: 15),

                      // Confirm Password field
                      TextField(
                        controller: konfirmasiPasswordController,
                        obscureText: _obscureText2,
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
                            Icons.lock_outline,
                            color: primaryColor,
                          ),
                          labelText: "Konfirmasi Password",
                          labelStyle: const TextStyle(color: Colors.grey),
                          errorText: errorTextKonfirmasiPassword,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15.0,
                            horizontal: 20.0,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText2
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText2 = !_obscureText2;
                              });
                            },
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            errorTextKonfirmasiPassword = null;
                          });
                        },
                        onSubmitted: (_) => _daftar(),
                      ),

                      const SizedBox(height: 30),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _daftar,
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
                                    "Daftar ",
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
