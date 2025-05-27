import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HalamanPrice extends StatefulWidget {
  const HalamanPrice({super.key});

  @override
  State<HalamanPrice> createState() => _HalamanPriceState();
}

class _HalamanPriceState extends State<HalamanPrice> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isEditing = false;

  // Price entry controllers
  final TextEditingController _memberWeekdayMorningController =
      TextEditingController();
  final TextEditingController _memberWeekdayEveningController =
      TextEditingController();
  final TextEditingController _memberWeekendController =
      TextEditingController();
  final TextEditingController _nonMemberWeekdayMorningController =
      TextEditingController();
  final TextEditingController _nonMemberWeekdayEveningController =
      TextEditingController();
  final TextEditingController _nonMemberWeekendController =
      TextEditingController();

  final List<Map<String, dynamic>> _priceEntries = [
    {
      'type': 'Member',
      'jam_mulai': 7,
      'jam_selesai': 14,
      'hari_mulai': 'Senin',
      'hari_selesai': 'Jumat',
      'controller': null,
      'id': null,
      'display_time': '07.00 - 14.00',
      'display_day': 'Senin - Jumat',
    },
    {
      'type': 'Member',
      'jam_mulai': 14,
      'jam_selesai': 23,
      'hari_mulai': 'Senin',
      'hari_selesai': 'Jumat',
      'controller': null,
      'id': null,
      'display_time': '14.00 - 23.00',
      'display_day': 'Senin - Jumat',
    },
    {
      'type': 'Member',
      'jam_mulai': 7,
      'jam_selesai': 23,
      'hari_mulai': 'Sabtu',
      'hari_selesai': 'Minggu',
      'controller': null,
      'id': null,
      'display_time': '07.00 - 23.00',
      'display_day': 'Sabtu - Minggu',
    },
    {
      'type': 'Non Member',
      'jam_mulai': 7,
      'jam_selesai': 14,
      'hari_mulai': 'Senin',
      'hari_selesai': 'Jumat',
      'controller': null,
      'id': null,
      'display_time': '07.00 - 14.00',
      'display_day': 'Senin - Jumat',
    },
    {
      'type': 'Non Member',
      'jam_mulai': 14,
      'jam_selesai': 23,
      'hari_mulai': 'Senin',
      'hari_selesai': 'Jumat',
      'controller': null,
      'id': null,
      'display_time': '14.00 - 23.00',
      'display_day': 'Senin - Jumat',
    },
    {
      'type': 'Non Member',
      'jam_mulai': 7,
      'jam_selesai': 23,
      'hari_mulai': 'Sabtu',
      'hari_selesai': 'Minggu',
      'controller': null,
      'id': null,
      'display_time': '07.00 - 23.00',
      'display_day': 'Sabtu - Minggu',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Assign controllers to price entries
    _priceEntries[0]['controller'] = _memberWeekdayMorningController;
    _priceEntries[1]['controller'] = _memberWeekdayEveningController;
    _priceEntries[2]['controller'] = _memberWeekendController;
    _priceEntries[3]['controller'] = _nonMemberWeekdayMorningController;
    _priceEntries[4]['controller'] = _nonMemberWeekdayEveningController;
    _priceEntries[5]['controller'] = _nonMemberWeekendController;

    _loadPrices();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _memberWeekdayMorningController.dispose();
    _memberWeekdayEveningController.dispose();
    _memberWeekendController.dispose();
    _nonMemberWeekdayMorningController.dispose();
    _nonMemberWeekdayEveningController.dispose();
    _nonMemberWeekendController.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);

    try {
      // Get prices from Firestore
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('harga').get();

      // Process the query results
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Find matching entry in our data structure
        for (var entry in _priceEntries) {
          if (_isMatchingEntry(entry, data)) {
            // Found matching entry - update controller and save document ID
            final TextEditingController controller =
                entry['controller'] as TextEditingController;
            controller.text = _formatPrice(data['harga'].toString());
            entry['id'] = doc.id;
            break;
          }
        }
      }

      // Set default values for any entries without data
      for (var entry in _priceEntries) {
        final TextEditingController controller =
            entry['controller'] as TextEditingController;
        if (controller.text.isEmpty) {
          controller.text = _formatPrice('50000');
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      // Set default values if fetch fails
      _setDefaultPrices();

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat harga: $e')));
      }
    }
  }

  bool _isMatchingEntry(
    Map<String, dynamic> entry,
    Map<String, dynamic> firestoreData,
  ) {
    // Check if the Firestore document matches our entry
    return firestoreData['type'] == entry['type'] &&
        firestoreData['jam_mulai'] == entry['jam_mulai'] &&
        firestoreData['jam_selesai'] == entry['jam_selesai'] &&
        firestoreData['hari_mulai'] == entry['hari_mulai'] &&
        firestoreData['hari_selesai'] == entry['hari_selesai'];
  }

  void _setDefaultPrices() {
    _memberWeekdayMorningController.text = _formatPrice('50000');
    _memberWeekdayEveningController.text = _formatPrice('50000');
    _memberWeekendController.text = _formatPrice('50000');
    _nonMemberWeekdayMorningController.text = _formatPrice('50000');
    _nonMemberWeekdayEveningController.text = _formatPrice('50000');
    _nonMemberWeekendController.text = _formatPrice('50000');
  }

  String _formatPrice(String price) {
    if (price.isEmpty) return '';
    // Format angka
    final formatter = NumberFormat('#,###');
    return formatter.format(int.parse(price));
  }

  String _unformatPrice(String formattedPrice) {
    // Menghapus karakter selain angka
    return formattedPrice.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _savePrices() async {
    setState(() => _isLoading = true);

    try {
      for (var entry in _priceEntries) {
        final controller = entry['controller'] as TextEditingController;
        final priceStr = _unformatPrice(controller.text).trim();

        if (priceStr.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Semua kolom harga harus diisi')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      for (var entry in _priceEntries) {
        final controller = entry['controller'] as TextEditingController;
        final priceStr = _unformatPrice(controller.text).trim();
        final price = int.parse(priceStr);
        final type = entry['type'] as String;
        final jamMulai = entry['jam_mulai'] as int;
        final jamSelesai = entry['jam_selesai'] as int;
        final hariMulai = entry['hari_mulai'] as String;
        final hariSelesai = entry['hari_selesai'] as String;

        final exists = await FirebaseService().checkHarga(
          type,
          jamMulai,
          jamSelesai,
          hariMulai,
          hariSelesai,
        );

        if (exists && entry['id'] != null) {
          await FirebaseFirestore.instance
              .collection('harga')
              .doc(entry['id'] as String)
              .update({'harga': price});
        } else {
          await FirebaseService().saveHarga(
            type,
            jamMulai,
            jamSelesai,
            hariMulai,
            hariSelesai,
            price,
          );

          if (entry['id'] == null) {
            final docId = await FirebaseService().getHargaDocumentId(
              type,
              jamMulai,
              jamSelesai,
              hariMulai,
              hariSelesai,
            );
            if (docId != null) {
              entry['id'] = docId;
            }
          }
        }
      }

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Harga telah diupdate'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal update harga: $e')));
      }
    }
  }

  Widget _buildPriceSection({
    required String title,
    required TextEditingController morningController,
    required TextEditingController eveningController,
    required TextEditingController weekendController,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDaySection(
              title: "Senin - Jumat",
              icon: Icons.radio_button_checked_outlined,
              morningController: morningController,
              eveningController: eveningController,
            ),
            const SizedBox(height: 16),
            _buildDaySection(
              title: "Sabtu - Minggu",
              icon: Icons.radio_button_checked_outlined,
              weekendController: weekendController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection({
    required String title,
    required IconData icon,
    TextEditingController? morningController,
    TextEditingController? eveningController,
    TextEditingController? weekendController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (morningController != null)
          _buildTimeRow(
            label: "07.00 - 14.00 :",
            controller: morningController,
          ),
        if (morningController != null) const SizedBox(height: 8),
        if (eveningController != null)
          _buildTimeRow(
            label: "14.00 - 23.00 :",
            controller: eveningController,
          ),
        if (weekendController != null)
          _buildTimeRow(
            label: "07.00 - 23.00 :",
            controller: weekendController,
          ),
      ],
    );
  }

  Widget _buildTimeRow({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: _isEditing,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              prefixText: 'Rp ',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: !_isEditing,
              fillColor: !_isEditing ? Colors.grey.shade100 : null,
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16),
            onChanged: (value) {
              // Format the input with thousand separators
              if (value.isNotEmpty) {
                final unformatted = _unformatPrice(value);
                if (unformatted.isNotEmpty) {
                  final formatted = _formatPrice(unformatted);
                  if (formatted != value) {
                    controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Harga")),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadPrices,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceSection(
                        title: "Member",
                        morningController: _memberWeekdayMorningController,
                        eveningController: _memberWeekdayEveningController,
                        weekendController: _memberWeekendController,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      _buildPriceSection(
                        title: "Non Member",
                        morningController: _nonMemberWeekdayMorningController,
                        eveningController: _nonMemberWeekdayEveningController,
                        weekendController: _nonMemberWeekendController,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 20),
                      _isEditing
                          ? SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _savePrices(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                disabledBackgroundColor: primaryColor
                                    .withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    borderRadius,
                                  ),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                "Simpan Harga",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  () => setState(() => _isEditing = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                disabledBackgroundColor: primaryColor
                                    .withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    borderRadius,
                                  ),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                "Edit Harga",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
    );
  }
}
