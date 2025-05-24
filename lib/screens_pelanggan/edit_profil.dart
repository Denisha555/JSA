import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<UserProfil> profil = [];

  // Individual error texts for each field
  String? errorTextUsername;
  String? errorTextPassword;
  String? errorTextKonfirmasiPassword;
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

  Future<void> _checkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');

    if (username == null) return;

    bool check = await FirebaseService().memberOrNonmember(username);

    if (!mounted) return;

    setState(() {
      isMember = check;
    });
  }

  Future<void> _getAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedUsername = prefs.getString('username');

      if (storedUsername == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username tidak ditemukan')),
          );
        }
        return;
      }

      profil = await FirebaseService().getProfilData(storedUsername);

      if (!mounted) return;

      if (profil.isNotEmpty) {
        setState(() {
          username = profil[0].username;
          namaController.text = profil[0].name;
          noTelpController.text = profil[0].phoneNumber;
          clubController.text = profil[0].club;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateForm() {
    bool isValid = true;

    setState(() {
      errorTextUsername = null;
      errorTextNama = null;
      errorTextNoTelp = null;
      errorTextClub = null;
    });

    // Validate full name
    if (namaController.text.trim().isEmpty) {
      setState(() {
        errorTextNama = 'Nama lengkap tidak boleh kosong';
      });
      isValid = false;
    }

    // Validate phone number
    if (noTelpController.text.trim().isEmpty) {
      setState(() {
        errorTextNoTelp = 'Nomor telepon tidak boleh kosong';
      });
      isValid = false;
    } else if (!RegExp(r'^\d{10,15}$').hasMatch(noTelpController.text.trim())) {
      setState(() {
        errorTextNoTelp = 'Format nomor telepon tidak valid';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseService().editProfil(
        username!,
        namaController.text.trim(),
        noTelpController.text.trim(),
        clubController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
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
  void initState() {
    super.initState();
    _checkStatus();
    _getAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Avatar Section
                    Container(
                      padding: const EdgeInsets.only(top: 20, bottom: 10),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            isMember ? Colors.blueAccent : Colors.grey[400]!,
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
                    ),

                    Text(username!, style: TextStyle(fontSize: 20)),

                    SizedBox(height: 10),

                    // Form Section
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Full Name field
                          TextField(
                            controller: namaController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: primaryColor,
                              ),
                              labelText: "Nama Lengkap",
                              labelStyle: const TextStyle(color: Colors.grey),
                              errorText: errorTextNama,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 20.0,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                errorTextNama = null;
                              });
                            },
                          ),

                          const SizedBox(height: 15),

                          // Club Name field
                          TextField(
                            controller: clubController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.groups,
                                color: primaryColor,
                              ),
                              labelText: "Nama Club (tidak wajib)",
                              labelStyle: const TextStyle(color: Colors.grey),
                              errorText: errorTextClub,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 20.0,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                errorTextClub = null;
                              });
                            },
                          ),

                          const SizedBox(height: 15),

                          // Phone Number field
                          TextField(
                            controller: noTelpController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                borderSide: const BorderSide(
                                  color: primaryColor,
                                  width: 2.0,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.phone,
                                color: primaryColor,
                              ),
                              labelText: "Nomor Telepon",
                              labelStyle: const TextStyle(color: Colors.grey),
                              errorText: errorTextNoTelp,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 20.0,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                errorTextNoTelp = null;
                              });
                            },
                          ),

                          const SizedBox(height: 30),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    borderRadius,
                                  ),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        "Simpan",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
