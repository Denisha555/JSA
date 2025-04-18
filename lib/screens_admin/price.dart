import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_1/services/firestore_service.dart';

class HalamanPrice extends StatefulWidget {
  const HalamanPrice({super.key});

  @override
  State<HalamanPrice> createState() => _HalamanPriceState();
}

class _HalamanPriceState extends State<HalamanPrice> {
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _uploadImage(BuildContext context) async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload ke Firebase Storage
      final fileName = basename(_selectedImage!.path);
      final ref = FirebaseStorage.instance.ref().child(
        'price_images/$fileName',
      );
      await ref.putFile(_selectedImage!);

      // 2. Ambil URL-nya
      final imageUrl = await ref.getDownloadURL();

      // 3. Simpan ke Firestore
      await FirebaseService().savePriceImage(imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gambar berhasil ditampilkan pada tampilan pengguna")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload gagal: $e")));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Price")),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 15.0,
            bottom: 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "Unggah Gambar Daftar Harga",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Upload gambar daftar harga untuk ditampilkan kepada pelanggan",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              // Image preview card
              Container(
                width: double.infinity,
                height: 380,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000).withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _selectedImage != null
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ],
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Belum ada gambar",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Tambahkan gambar daftar harga di sini",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                ),
              ),

              const SizedBox(height: 15),

              // Action buttons
              if (_selectedImage == null)
                _buildActionButton(
                  label: "Pilih Gambar",
                  onPressed: () => _pickImage(context),
                  color: primaryColor,
                ),
              if (_selectedImage != null)
                Row(
                  children: [
                    // Upload button
                    Expanded(
                      child: _buildActionButton(
                        label: "Upload Gambar",
                        onPressed: () => _uploadImage(context),
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Change image button
                    Expanded(
                      child: _buildActionButton(
                        label: "Ganti Gambar",
                        onPressed: () => _pickImage(context),
                        color: Colors.blue,
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
