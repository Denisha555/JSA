import 'package:flutter/material.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPassword extends StatefulWidget {
  const EditPassword({super.key});

  @override
  State<EditPassword> createState() => _EditPasswordState();
}

class _EditPasswordState extends State<EditPassword> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordController2 = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool obscureText = true;
  bool obscureText2 = true;

  Future<void> _updatePassword(String newPassword) async {
    if (newPassword.trim().isEmpty) {
      showErrorSnackBar(context, 'Password tidak boleh kosong');
      return;
    }

    if (newPassword.trim().length < 6) {
      showErrorSnackBar(context, 'Password minimal 6 karakter');
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');
      if (username != null) {
        await FirebaseUpdateUser().updateUser(
          'password',
          username,
          newPassword.trim(),
        );
        // SharedPreferences prefs = await SharedPreferences.getInstance();
        // await prefs.setString('password', newPassword.trim());

        if (!mounted) return;
        showSuccessSnackBar(context, 'Password berhasil diperbarui!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      showErrorSnackBar(context, 'Error updating password: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ubah Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Password baru
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.trim().length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Konfirmasi password
                  TextFormField(
                    controller: passwordController2,
                    obscureText: obscureText2,
                    decoration: InputDecoration(
                      hintText: 'Konfirmasi password baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText2
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText2 = !obscureText2;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Konfirmasi password tidak boleh kosong';
                      }
                      if (value != passwordController.text) {
                        return 'Password tidak sama';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Tombol aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            _updatePassword(passwordController.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 45),
                        ),
                        child: const Text('Perbarui'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
