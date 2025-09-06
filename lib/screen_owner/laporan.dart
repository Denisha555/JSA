import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  bool _isLoading = false;

  List<TimeSlotModel>? _laporanData;
  Map<String, dynamic>? _laporanSummary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card untuk pemilihan tanggal
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tanggal Mulai
                      _buildDatePickerField(
                        label: 'Tanggal Mulai',
                        selectedDate: _tanggalMulai,
                        onTap: () => _pilihTanggal(context, true),
                        icon: Icons.calendar_today,
                      ),

                      const SizedBox(height: 12),

                      // Tanggal Selesai
                      _buildDatePickerField(
                        label: 'Tanggal Selesai',
                        selectedDate: _tanggalSelesai,
                        onTap: () => _pilihTanggal(context, false),
                        icon: Icons.event,
                      ),

                      const SizedBox(height: 20),

                      // Tombol Generate Laporan
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            _isLoading ||
                                    _tanggalMulai == null ||
                                    _tanggalSelesai == null
                                ? null
                                : await _getLaporan();
                          },
                          label: Text(
                            _isLoading ? 'Memuat...' : 'Tampilkan Laporan',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tampilan Laporan
              if (_laporanData != null) ...[
                const Text(
                  'Hasil Laporan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Tanggal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Pendapatan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ..._laporanSummary!.entries.map(
                      (entry) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(entry.key), // tanggal
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Rp ${entry.value}',
                            ), // total harga
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else if (_isLoading) ...[
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Memuat laporan...'),
                    ],
                  ),
                ),
              ] else ...[
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pilih periode tanggal untuk melihat laporan',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedDate != null
                      ? _formatTanggal(selectedDate)
                      : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        selectedDate != null
                            ? Colors.black87
                            : Colors.grey[500],
                    fontWeight:
                        selectedDate != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void generateLaporan() {
    _laporanSummary ??= <String, dynamic>{};

    for (var data in _laporanData!) {
        if (_laporanSummary!.containsKey(data.date)) {
            _laporanSummary![data.date] = _laporanSummary![data.date] + data.price;
        } else {
            _laporanSummary![data.date] = data.price;
        }
    }

    setState(() {
        _laporanSummary = _laporanSummary;
    });
}

  Future<void> _pilihTanggal(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _tanggalMulai = pickedDate;
          // Reset tanggal selesai jika lebih kecil dari tanggal mulai
          if (_tanggalSelesai != null &&
              _tanggalSelesai!.isBefore(pickedDate)) {
            _tanggalSelesai = null;
          }
        } else {
          // Validasi tanggal selesai tidak boleh sebelum tanggal mulai
          if (_tanggalMulai != null && pickedDate.isBefore(_tanggalMulai!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Tanggal selesai tidak boleh sebelum tanggal mulai',
                ),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _tanggalSelesai = pickedDate;
        }
      });
    }
  }

  Future<void> _getLaporan() async {
    if (_tanggalMulai == null || _tanggalSelesai == null) return;

    setState(() {
      _isLoading = true;
    });

    final data = await FirebaseGetBooking().getBookingForReport(
      formatDateStr(_tanggalMulai!),
      formatDateStr(_tanggalSelesai!),
    );

    print('Laporan data: ${data.length} slots');

    setState(() {
      _laporanData = data;
      _isLoading = false;
    });

    generateLaporan();
  }

  String _formatTanggal(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} M';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} rb';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
