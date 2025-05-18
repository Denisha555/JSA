import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
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

class HalamanJadwalTabs extends StatefulWidget {
  @override
  _HalamanJadwalTabsState createState() => _HalamanJadwalTabsState();
}

class _HalamanJadwalTabsState extends State<HalamanJadwalTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  List<JadwalOperasional> jadwalKhusus = [];
  DateTime tanggalKhusus = DateTime.now();
  TimeOfDay jamMulaiKhusus = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay jamSelesaiKhusus = TimeOfDay(hour: 18, minute: 0);
  bool isClose = false;
  String? editingDocId;

  // Loading state variables
  bool _isLoading = false;
  bool _isLoadingJadwal = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add initialization for loading jadwal
    // initializeFormatting('id_ID', null).then((_) {
    _fetchJadwalKhusus();
    // });
  }

  Future<void> _fetchJadwalKhusus() async {
    setState(() {
      _isLoadingJadwal = true;
    });

    try {
      // Fetch jadwal from Firestore
      // This is a placeholder - implement your actual fetching logic
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay

      // Example data for illustration
      jadwalKhusus = [];

      // You should implement actual data fetching here
      // Example: jadwalKhusus = await FirebaseService().getJadwalKhusus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat jadwal: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingJadwal = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.edit_calendar), text: 'Input Jadwal'),
            Tab(icon: Icon(Icons.calendar_view_week), text: 'Daftar Jadwal'),
          ],
        ),
        actions: [
          if (_isLoadingJadwal && _tabController.index == 1)
            Container(
              margin: EdgeInsets.only(right: 16),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // Input Jadwal Tab
              _buildInputJadwalTab(),

              // Daftar Jadwal Tab
              _buildDaftarJadwalTab(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputJadwalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editingDocId != null ? "Edit Jadwal" : "Tambah Jadwal Baru",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tanggalKhusus,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) setState(() => tanggalKhusus = picked);
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
                    onChanged: (val) => setState(() => isClose = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                SizedBox(height: 16),
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
                Row(
                  children: [
                    if (editingDocId != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    setState(() {
                                      editingDocId = null;
                                      tanggalKhusus = DateTime.now();
                                      jamMulaiKhusus = TimeOfDay(
                                        hour: 9,
                                        minute: 0,
                                      );
                                      jamSelesaiKhusus = TimeOfDay(
                                        hour: 18,
                                        minute: 0,
                                      );
                                      isClose = false;
                                    });
                                  },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("Batal"),
                        ),
                      ),
                    if (editingDocId != null) SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _saveJadwal(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  editingDocId != null ? "Update" : "Simpan",
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadOrCreateSlots(DateTime selectedDate) async {
    setState(() => _isLoading = true);
    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final slots = await FirebaseService().getTimeSlotsByDate(dateStr);

    if (slots.isEmpty) {
      debugPrint('Slots not exist');
      await FirebaseService().generateSlotsOneDay(selectedDate);

      await FirebaseService().closeUseTimeRange(
          tanggalKhusus,
          formatTime(jamMulaiKhusus),
          formatTime(jamSelesaiKhusus),
        );
    
    } else {
      debugPrint('Slots already exist');
      await FirebaseService().closeUseTimeRange(
          tanggalKhusus,
          formatTime(jamMulaiKhusus),
          formatTime(jamSelesaiKhusus),
        );
    }
  }

  Future<void> _saveJadwal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      if (isClose) {
        debugPrint('isClose true: $isClose');
        await FirebaseService().closeAllDay(tanggalKhusus);
      } else {
        debugPrint('isClose false: $isClose');
        await _loadOrCreateSlots(tanggalKhusus);
      }

      // Reset form after saving
      setState(() {
        editingDocId = null;
        tanggalKhusus = DateTime.now();
        jamMulaiKhusus = TimeOfDay(hour: 9, minute: 0);
        jamSelesaiKhusus = TimeOfDay(hour: 18, minute: 0);
        isClose = false;
      });

      if (!mounted) return;
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jadwal berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh jadwal list and switch to the list tab
      await _fetchJadwalKhusus();
      _tabController.animateTo(1);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan jadwal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDaftarJadwalTab() {
    if (_isLoadingJadwal) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Memuat jadwal...',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return jadwalKhusus.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Belum ada jadwal khusus",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        )
        : RefreshIndicator(
          onRefresh: _fetchJadwalKhusus,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          Icon(
                            jadwal.close
                                ? Icons.do_not_disturb_on
                                : Icons.access_time,
                            color: jadwal.close ? Colors.red : primaryColor,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formatTanggal(jadwal.tanggal),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        jadwal.close
                            ? 'Tutup Sepanjang Hari'
                            : 'Jam Operasional: ${jadwal.jamMulai!.format(context)} - ${jadwal.jamSelesai!.format(context)}',
                        style: TextStyle(fontSize: 15),
                      ),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: Icon(Icons.edit, size: 18),
                            label: Text("Edit"),
                            onPressed:
                                _isLoading ? null : () => _editJadwal(jadwal),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          TextButton.icon(
                            icon: Icon(Icons.delete, size: 18),
                            label: Text("Hapus"),
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      if (jadwal.id != null) {
                                        _showDeleteConfirmation(jadwal.id!);
                                      }
                                    },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
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

  void _editJadwal(JadwalOperasional jadwal) {
    setState(() {
      editingDocId = jadwal.id;
      tanggalKhusus = jadwal.tanggal;
      isClose = jadwal.close;
      if (!jadwal.close) {
        jamMulaiKhusus = jadwal.jamMulai!;
        jamSelesaiKhusus = jadwal.jamSelesai!;
      }
    });

    _tabController.animateTo(0);
  }

  void _showDeleteConfirmation(String jadwalId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Anda yakin ingin menghapus jadwal ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Batal"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteJadwal(jadwalId);
                },
                child: Text("Hapus"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteJadwal(String jadwalId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Implement deletion logic - this is a placeholder
      // await FirebaseService().deleteJadwal(jadwalId);
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay

      // Update local list
      setState(() {
        jadwalKhusus.removeWhere((jadwal) => jadwal.id == jadwalId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jadwal berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus jadwal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
