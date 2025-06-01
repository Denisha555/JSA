import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class HalamanLapangan extends StatefulWidget {
  const HalamanLapangan({super.key});

  @override
  State<HalamanLapangan> createState() => _HalamanLapanganState();
}

class _HalamanLapanganState extends State<HalamanLapangan> with SingleTickerProviderStateMixin {
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _nomorController = TextEditingController();
  File? _imageFile;
  String? _imageBase64;
  bool _isLoading = false;
  String? _currentLapanganId;
  bool _isEditing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _nomorController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _deskripsiController.clear();
    _nomorController.clear();
    setState(() {
      _imageFile = null;
      _imageBase64 = null;
      _currentLapanganId = null;
      _isEditing = false;
    });
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Pilih Sumber Gambar'),
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
        maxWidth: 800,  // Batasi ukuran untuk mengurangi ukuran base64
        maxHeight: 600,
        imageQuality: 70,  // Kompres gambar
      );
      
      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _imageFile = file;
          _imageBase64 = base64String;
        });
      }
    }
  }

  Future<void> _simpanLapangan() async {
    // validasi
    String deskripsi = _deskripsiController.text.trim();
    String nomor = _nomorController.text.trim();

    if (nomor.isEmpty) {
      _showSnackBar('Nomor lapangan tidak boleh kosong');
      return;
    }

    // Cek lapangan yang sudah dibuat (kecuali saat editing)
    if (!_isEditing) {
      bool isLapanganExist = await FirebaseService().checkLapangan(nomor);
      if (isLapanganExist) {
        _showSnackBar('Nomor lapangan sudah ada');
        return;
      }
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Buat data lapangan
      final lapanganData = {
        'nomor': nomor,
        'deskripsi': deskripsi,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Tambahkan imageBase64 jika ada
      if (_imageBase64 != null) {
        lapanganData['image'] = _imageBase64!;
      }

      // Jika editing, update dokumen yang ada
      if (_isEditing && _currentLapanganId != null) {
        await FirebaseFirestore.instance
            .collection('lapangan')
            .doc(_currentLapanganId)
            .update(lapanganData);
        _showSnackBar('Lapangan berhasil diperbarui');
      } else {
        // Jika baru, tambahkan timestamp pembuatan
        lapanganData['createdAt'] = FieldValue.serverTimestamp();

        bool check = await FirebaseService().checkLapangan(nomor);
        if (check) {
          _showSnackBar('Nomor lapangan sudah ada');
          return;
        }
        
        // Tambahkan dokumen baru
        await FirebaseFirestore.instance
            .collection('lapangan')
            .add(lapanganData);
        _showSnackBar('Lapangan berhasil disimpan');
      }

      // Reset form
      _resetForm();
      setState(() {
        _isLoading = false;
      });
      
      // Pindah ke tab daftar lapangan
      _tabController.animateTo(1);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
      ),
    );
  }

  Future<void> _editLapangan(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    setState(() {
      _currentLapanganId = doc.id;
      _isEditing = true;
      _nomorController.text = data['nomor'] ?? '';
      _deskripsiController.text = data['deskripsi'] ?? '';
      _imageBase64 = data['image']; // Set base64 string dari database
      _imageFile = null; // Reset file image karena kita pakai base64
    });
    
    // Pindah ke tab input form
    _tabController.animateTo(0);
  }

  Future<void> _hapusLapangan(String docId) async {
    try {
      // Konfirmasi hapus
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus lapangan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
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
      
      // Hapus dokumen
      await FirebaseService().hapusLapangan(docId);
      
      setState(() {
        _isLoading = false;
      });
      
      _showSnackBar('Lapangan berhasil dihapus');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Widget _buildImageWidget() {
    if (_imageFile != null) {
      // Tampilkan gambar dari file yang baru dipilih
      return Image.file(_imageFile!, fit: BoxFit.cover);
    } else if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
      // Tampilkan gambar dari base64 string (untuk edit mode)
      try {
        Uint8List bytes = base64Decode(_imageBase64!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error, size: 50),
        );
      }
    } else {
      // Tampilkan placeholder
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate, size: 64, color: primaryColor),
          SizedBox(height: 10),
          Text(
            'Tap untuk pilih gambar lapangan',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildInputForm() {
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
                  Text(
                    _isEditing ? 'Edit Lapangan' : 'Tambah Lapangan Baru',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nomorController,
                    decoration: InputDecoration(
                      labelText: 'Nomor Lapangan',
                      helperText: 'Contoh format: 01, 02, 03, ...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.numbers_rounded, color: primaryColor),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deskripsiController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.description_outlined, color: primaryColor),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _simpanLapangan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isEditing ? 'Perbarui' : 'Simpan',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _resetForm(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Batal', style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLapanganList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lapangan')
          .orderBy('nomor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.highlight_off_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Belum ada data lapangan',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String id = doc.id;
            final String nomor = data['nomor'] ?? '';
            final String deskripsi = data['deskripsi'] ?? '';
            final String? imageBase64 = data['image'];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: imageBase64 != null && imageBase64.isNotEmpty
                        ? Image.memory(
                            base64Decode(imageBase64),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, size: 50),
                              );
                            },
                          )
                        : Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, size: 50),
                          ),
                  ),
                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Lapangan #$nomor',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit, color: primaryColor),
                              onPressed: () => _editLapangan(doc),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _hapusLapangan(id),
                              tooltip: 'Hapus',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (deskripsi.isNotEmpty)
                          Text(
                            deskripsi,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lapangan',
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
            Tab(
              icon: Icon(Icons.add_box_outlined),
              text: 'Input Lapangan',
            ),
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'Daftar Lapangan',
            ),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildInputForm(),
              _buildLapanganList(),
            ],
          ),
    );
  }
}