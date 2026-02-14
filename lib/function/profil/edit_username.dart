import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';
import 'package:flutter_application_1/screens_pelanggan/profile.dart';
import 'package:flutter_application_1/services/time_slot/firebase_get_time_slot.dart';
import 'package:flutter_application_1/services/time_slot/firebase_update_time_slot.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';

class EditUsername extends StatefulWidget {
  const EditUsername({super.key});

  @override
  State<EditUsername> createState() => _EditUsernameState();
}

class _EditUsernameState extends State<EditUsername> {
  final TextEditingController usernameController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> _updateUsername(String oldUsername, String newUsername) async {
    if (newUsername.trim().isEmpty) {
      showErrorSnackBar(context, 'Username tidak boleh kosong');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('newUsername: $newUsername, oldUsername: $oldUsername');
      await FirebaseUpdateUser().updateUser('username', oldUsername, newUsername.trim());

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', newUsername.trim());

      await FirebaseUpdateTimeSlot().updateUsernameTimeSlots(oldUsername, newUsername);
    
      if (!mounted) return;
      showSuccessSnackBar(context, 'Username berhasil diperbarui!');
      if (mounted) Navigator.of(context).pop();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  PilihHalamanPelanggan(selectedIndex: 2)));
    } catch (e) {
      showErrorSnackBar(context, 'Gagal memperbarui username: $e');
      print('Error updating username: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!formKey.currentState!.validate()) return;

    final newUsername = usernameController.text.trim();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentUsername = prefs.getString('username');

    if (currentUsername == null) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Username saat ini tidak ditemukan');
      return;
    }

    final isUsed = await FirebaseCheckUser().checkExistence('username', newUsername);
    if (isUsed) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Username sudah digunakan');
      return;
    }

    await _updateUsername(currentUsername, newUsername);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ubah Username',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: 'Masukkan Username Baru',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 45),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Perbarui'),
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
