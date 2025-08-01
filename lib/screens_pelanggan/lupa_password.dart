import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HalamanLupaPassword extends StatefulWidget {
  const HalamanLupaPassword({super.key});

  @override
  State<HalamanLupaPassword> createState() => _HalamanLupaPasswordState();
}

class _HalamanLupaPasswordState extends State<HalamanLupaPassword> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  String? _verificationId;
  String? _currentUsername;
  bool _otpSent = false;
  bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cariUserDanKirimOTP() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar('Username wajib diisi');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showSnackBar('User tidak ditemukan');
        return;
      }

      final data = query.docs.first.data();
      final phone = data['phoneNumber'] as String;

      // Format ke internasional
      String phoneIntl = phone.startsWith('0')
          ? '+62${phone.substring(1)}'
          : phone;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneIntl,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar('Verifikasi gagal: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _otpSent = true;
            _verificationId = verificationId;
            _currentUsername = username;
          });
          _showSnackBar('Kode OTP telah dikirim ke nomor user');
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifikasiOtpDanUpdatePassword() async {
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (otp.isEmpty || newPassword.isEmpty) {
      _showSnackBar('OTP dan password baru wajib diisi');
      return;
    }

    if (_verificationId == null || _currentUsername == null) {
      _showSnackBar('Verifikasi belum dilakukan');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _currentUsername)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showSnackBar('User tidak ditemukan saat update password');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(query.docs.first.id)
          .update({'password': newPassword});

      _showSnackBar('Password berhasil diperbarui');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Gagal verifikasi atau update password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _otpSent
            ? Column(
                children: [
                  TextField(
                    controller: _otpController,
                    decoration: const InputDecoration(labelText: 'Kode OTP'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(labelText: 'Password Baru'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifikasiOtpDanUpdatePassword,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Verifikasi & Ganti Password'),
                  ),
                ],
              )
            : Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Masukkan Username'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _cariUserDanKirimOTP,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Kirim OTP ke Nomor User'),
                  ),
                ],
              ),
      ),
    );
  }
}
