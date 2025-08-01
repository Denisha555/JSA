import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/model/user_model.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';


class HalamanEditProfil extends StatefulWidget {
  const HalamanEditProfil({super.key});

  @override
  State<HalamanEditProfil> createState() => _HalamanEditProfilState();
}

class _HalamanEditProfilState extends State<HalamanEditProfil> {
  bool _isLoading = false;
  final TextEditingController namaController = TextEditingController();
  final TextEditingController noTelpController = TextEditingController();
  final TextEditingController clubController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<UserModel> profil = [];
  
  // Error texts for form validation
  String? errorTextNama;
  String? errorTextNoTelp;
  String? errorTextClub;
  
  String? username;
  bool isMember = false;

  @override
  void dispose() {
    namaController.dispose();
    noTelpController.dispose();
    clubController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkStatus();
    await _getAllData();
  }

  Future<void> _checkStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedUsername = prefs.getString('username');

      if (storedUsername == null || !mounted) return;

      String type = await FirebaseCheckUser().checkUserType(storedUsername);
      if (type == 'member') {
        setState(() {
          isMember = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking member status: $e');
    }
  }

  Future<void> _getAllData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedUsername = prefs.getString('username');

      if (storedUsername == null) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Username tidak ditemukan');
        return;
      }

      profil = await FirebaseGetUser().getUserByUsername(storedUsername);

      if (profil.isNotEmpty) {
        setState(() {
          username = profil[0].username;
          namaController.text = profil[0].name;
          noTelpController.text = profil[0].noTelp;
          clubController.text = profil[0].club;
        });
      } else {
        setState(() {
          username = storedUsername;
        });
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal memuat data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Enhanced validation with better rules
  bool _validateForm() {
    bool isValid = true;

    setState(() {
      errorTextNama = null;
      errorTextNoTelp = null;
      errorTextClub = null;
    });

    // Validate full name
    String fullName = namaController.text.trim();
    if (fullName.isEmpty) {
      setState(() {
        errorTextNama = 'Nama lengkap tidak boleh kosong';
      });
      isValid = false;
    } else if (fullName.length < 2) {
      setState(() {
        errorTextNama = 'Nama minimal 2 karakter';
      });
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(fullName)) {
      setState(() {
        errorTextNama = 'Nama hanya boleh berisi huruf dan spasi';
      });
      isValid = false;
    }

    // Validate phone number
    String phoneNumber = noTelpController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        errorTextNoTelp = 'Nomor telepon tidak boleh kosong';
      });
      isValid = false;
    } else if (!_isValidPhoneNumber(phoneNumber)) {
      setState(() {
        errorTextNoTelp = 'Format nomor telepon tidak valid';
      });
      isValid = false;
    }

    return isValid;
  }

  // Phone number validation helper
  bool _isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters for validation
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Indonesian phone number patterns
    // Mobile: 08xxxxxxxx (11-13 digits total)
    // Alternative mobile: +628xxxxxxxx or 628xxxxxxxx
    if (cleanNumber.startsWith('08') && cleanNumber.length >= 10 && cleanNumber.length <= 13) {
      return true;
    }
    if (cleanNumber.startsWith('628') && cleanNumber.length >= 11 && cleanNumber.length <= 14) {
      return true;
    }
    
    return false;
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseUpdateUser().updateProfil(
        username!,
        namaController.text.trim(),
        clubController.text.trim(),
        noTelpController.text.trim(),
      );

      if (mounted) {
        showSuccessSnackBar(context, 'Profil berhasil disimpan');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal menyimpan profil: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? errorText,
    TextInputType? keyboardType,
    required VoidCallback onChanged,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            prefixIcon: Icon(icon, color: primaryColor),
            labelText: labelText,
            hintText: hintText,
            labelStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 20.0,
            ),
          ),
          onChanged: (_) => onChanged(),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: isMember ? Colors.blueAccent : Colors.grey[400]!,
            child: Text(
              username != null && username!.isNotEmpty
                  ? username![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            username ?? 'Loading...',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isMember ? Colors.green.withValues(alpha:0.2) : Colors.grey.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isMember ? 'Member' : 'Non-Member',
              style: TextStyle(
                color: isMember ? Colors.green[700] : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Avatar Section
                    _buildProfileAvatar(),

                    const SizedBox(height: 20),

                    // Form Section
                    Column(
                      children: [
                        // Full Name field
                        _buildTextField(
                          controller: namaController,
                          labelText: "Nama Lengkap",
                          hintText: "Masukkan nama lengkap Anda",
                          icon: Icons.person,
                          errorText: errorTextNama,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                          ],
                          onChanged: () => setState(() => errorTextNama = null),
                        ),

                        const SizedBox(height: 16),

                        // Club Name field
                        _buildTextField(
                          controller: clubController,
                          labelText: "Nama Club",
                          hintText: "Opsional - nama club/tim Anda",
                          icon: Icons.groups,
                          errorText: errorTextClub,
                          onChanged: () => setState(() => errorTextClub = null),
                        ),

                        const SizedBox(height: 16),

                        // Phone Number field
                        _buildTextField(
                          controller: noTelpController,
                          labelText: "Nomor Telepon",
                          hintText: "Contoh: 08123456789",
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          errorText: errorTextNoTelp,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                          ],
                          onChanged: () => setState(() => errorTextNoTelp = null),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(borderRadius),
                              ),
                              elevation: 2,
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Simpan Perubahan",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}