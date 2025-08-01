import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/services/event_promo/firebase_add_event_promo.dart';
import 'package:flutter_application_1/services/event_promo/firebase_delete_event_promo.dart';


class HalamanPromoEvent extends StatefulWidget {
  const HalamanPromoEvent({super.key});

  @override
  State<HalamanPromoEvent> createState() => _HalamanPromoEventState();
}

class _HalamanPromoEventState extends State<HalamanPromoEvent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Pilih Sumber Gambar'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt, color: primaryColor),
                  SizedBox(width: 10),
                  Text('Kamera'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Row(
                children: [
                  Icon(Icons.photo_library, color: primaryColor),
                  SizedBox(width: 10),
                  Text('Galeri'),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (source != null) {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024, // Batasi ukuran untuk mengurangi ukuran base64
        maxHeight: 1024,
        imageQuality: 85, // Kompres gambar
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _imageFile = null;
    });
  }

  // Fungsi untuk mengkonversi gambar ke base64
  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);
      return base64String;
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  Future<void> _simpanPromo() async {
    if (_imageFile == null) {
      showErrorSnackBar(context, 'Silakan pilih gambar terlebih dahulu');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Konversi gambar ke base64
      String base64Image = await _convertImageToBase64(_imageFile!);

      // Simpan ke Firestore dengan base64
      await FirebaseAddEventPromo().addEventPromo(base64Image, DateTime.now());

      if (!mounted) return; 

      showSuccessSnackBar(context, 'Promo berhasil diunggah');
      _resetForm();
      _tabController.animateTo(1);
    } catch (e) {
      showErrorSnackBar(context, 'Gagal mengunggah promo: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPromoForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Promo Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Image picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 64,
                                      color: primaryColor,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Tap untuk pilih gambar promo',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Upload button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _simpanPromo,
                      label:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Unggah Promo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
            .collection('promo_event')
            .orderBy('createdAt', descending: true)
            .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada promo tersedia',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String base64Image = data['gambar'] ?? '';
            final Timestamp? createdAt = data['createdAt'];

            String dateInfo = '';
            if (createdAt != null) {
              dateInfo =
                  'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())}';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image from base64
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child:
                        base64Image.isNotEmpty
                            ? Image.memory(
                              base64Decode(base64Image),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                );
                              },
                            )
                            : Container(
                              height: 180,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                  ),
                  // Date info and delete button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (dateInfo.isNotEmpty) ...[
                          const Icon(
                            Icons.schedule,
                            color: primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateInfo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePromo(doc.id),
                          tooltip: 'Hapus',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deletePromo(String docId) async {
    // Konfirmasi hapus
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text('Apakah Anda yakin ingin menghapus promo ini?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Hapus dokumen dari Firestore
      await FirebaseDeleteEventPromo().deleteEventPromo(docId);
      _resetForm();
      
      if (!mounted) return; 
      showSuccessSnackBar(context, 'Promo berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal menghapus promo: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Promo & Event',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.add_box_outlined), text: 'Tambah Promo'),
            Tab(icon: Icon(Icons.campaign_outlined), text: 'Promo Berjalan'),
          ],
        ),
      ),
      body:
          _isLoading && _tabController.index != 1
              ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
              : TabBarView(
                controller: _tabController,
                children: [_buildPromoForm(), _buildPromoList()],
              ),
    );
  }
}
