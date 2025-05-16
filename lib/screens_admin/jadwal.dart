import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

extension StringToDateTime on String {
  DateTime toDate() {
    final parts = split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

class JadwalOperasional {
  final DateTime tanggal;
  final TimeOfDay? jamMulai;
  final TimeOfDay? jamSelesai;
  final bool close;
  final String? id;

  JadwalOperasional({
    required this.tanggal,
    this.jamMulai,
    this.jamSelesai,
    this.close = false,
    this.id,
  });
}

class HalamanJadwal extends StatefulWidget {
  @override
  _HalamanJadwalState createState() => _HalamanJadwalState();
}

class _HalamanJadwalState extends State<HalamanJadwal> {
  final _formKey = GlobalKey<FormState>();
  List<JadwalOperasional> jadwalKhusus = [];
  DateTime tanggalKhusus = DateTime.now();
  TimeOfDay jamMulaiKhusus = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay jamSelesaiKhusus = TimeOfDay(hour: 18, minute: 0);
  bool isClose = false;
  String? editingDocId;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) => _fetchJadwalKhusus());
  }

  void _fetchJadwalKhusus() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance
              .collection('jadwal_operasional')
              .orderBy('tanggal')
              .get();

      final now = DateTime.now();

      setState(() {
        jadwalKhusus =
            snapshot.docs
                .where(
                  (doc) => (doc['tanggal'] as Timestamp).toDate().isAfter(
                    now.subtract(Duration(days: 1)),
                  ),
                )
                .map((doc) {
                  final isClose = doc['close'] == true;
                  return JadwalOperasional(
                    tanggal: (doc['tanggal'] as Timestamp).toDate(),
                    jamMulai:
                        isClose
                            ? null
                            : TimeOfDay.fromDateTime(
                              (doc['jam_mulai'] as String).toDate(),
                            ),
                    jamSelesai:
                        isClose
                            ? null
                            : TimeOfDay.fromDateTime(
                              (doc['jam_selesai'] as String).toDate(),
                            ),
                    close: isClose,
                  );
                })
                .toList();
      });
    } catch (e) {
      print('Error : $e');
    }
  }

  void _addOrUpdateJadwalKhusus() async {
    // Validasi duplikat
    final duplicate = jadwalKhusus.any((j) {
      final sameDay = isSameDay(j.tanggal, tanggalKhusus);
      final sameTime =
          j.jamMulai == jamMulaiKhusus && j.jamSelesai == jamSelesaiKhusus;
      final sameClose = j.close == isClose;
      return sameDay && (isClose || sameTime);
    });

    if (duplicate && editingDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jadwal pada tanggal dan jam yang sama sudah ada, silahkan edit pada bagian daftar jadwal.',
          ),
        ),
      );
      return;
    }

    final data = {
      'tanggal': tanggalKhusus,
      'jam_mulai': isClose ? null : formatTime(jamMulaiKhusus),
      'jam_selesai': isClose ? null : formatTime(jamSelesaiKhusus),
      'close': isClose,
    };

    if (editingDocId != null) {
      // Update
      await FirebaseFirestore.instance
          .collection('jadwal_operasional')
          .doc(editingDocId)
          .update(data);
      editingDocId = null;
    } else {
      // Add new
      await FirebaseFirestore.instance
          .collection('jadwal_operasional')
          .add(data);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Jadwal berhasil disimpan.')));
    _fetchJadwalKhusus();
  }

  void _deleteJadwal(DateTime tanggal) async {
    var snapshot =
        await FirebaseFirestore.instance
            .collection('jadwal_operasional')
            .where('tanggal', isEqualTo: tanggal)
            .get();

    for (var doc in snapshot.docs) {
      await FirebaseFirestore.instance
          .collection('jadwal_operasional')
          .doc(doc.id)
          .delete();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Jadwal berhasil dihapus.')));
    _fetchJadwalKhusus();
  }

  void _editJadwal(DateTime tanggal) async {
    var snapshot =
        await FirebaseFirestore.instance
            .collection('jadwal_operasional')
            .where('tanggal', isEqualTo: tanggal)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      setState(() {
        editingDocId = doc.id;
        tanggalKhusus = (doc['tanggal'] as Timestamp).toDate();
        isClose = doc['close'] == true;
        jamMulaiKhusus =
            isClose
                ? TimeOfDay(hour: 9, minute: 0)
                : TimeOfDay.fromDateTime((doc['jam_mulai'] as String).toDate());
        jamSelesaiKhusus =
            isClose
                ? TimeOfDay(hour: 18, minute: 0)
                : TimeOfDay.fromDateTime(
                  (doc['jam_selesai'] as String).toDate(),
                );
      });
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String formatTanggal(DateTime date) {
    final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Jadwal'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Input Jadwal Operasional Khusus",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tanggalKhusus,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null)
                            setState(() => tanggalKhusus = picked);
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: "Tanggal",
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: formatTanggal(tanggalKhusus),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CheckboxListTile(
                          title: Text("Tutup Sepanjang Hari"),
                          value: isClose,
                          onChanged:
                              (val) => setState(() => isClose = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      SizedBox(height: 8),
                      if (!isClose)
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: jamMulaiKhusus,
                                );
                                if (picked != null)
                                  setState(() => jamMulaiKhusus = picked);
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: "Jam Mulai",
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.access_time),
                                  ),
                                  controller: TextEditingController(
                                    text: jamMulaiKhusus.format(context),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: jamSelesaiKhusus,
                                );
                                if (picked != null)
                                  setState(() => jamSelesaiKhusus = picked);
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: "Jam Selesai",
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.access_time),
                                  ),
                                  controller: TextEditingController(
                                    text: jamSelesaiKhusus.format(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addOrUpdateJadwalKhusus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            editingDocId != null ? "Update" : "Simpan",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Daftar Jadwal Operasional Khusus",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: jadwalKhusus.length,
              itemBuilder: (context, index) {
                final jadwal = jadwalKhusus[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatTanggal(jadwal.tanggal),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          jadwal.close
                              ? 'Tutup Sepanjang Hari'
                              : 'Jam Operasional: ${jadwal.jamMulai!.format(context)} - ${jadwal.jamSelesai!.format(context)}',
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: primaryColor),
                              onPressed: () => _editJadwal(jadwal.tanggal),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteJadwal(jadwal.tanggal),
                              tooltip: 'Hapus',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
