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

class HalamanJadwal extends StatefulWidget {
  @override
  _HalamanJadwalState createState() => _HalamanJadwalState();
}

class _HalamanJadwalState extends State<HalamanJadwal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  List<AllCloseDay> jadwalKhusus = [];
  DateTime tanggalKhusus = DateTime.now().add(Duration(days: 1)); // Default tomorrow
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
    _init();
  }

  Future<void> _init() async {
    await initializeDateFormatting('id_ID', null);
    await _fetchJadwalKhusus();
  }

  Future<void> _fetchJadwalKhusus() async {
    setState(() {
      _isLoadingJadwal = true;
    });

    try {
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      final hasil = await FirebaseService().getAllCloseDay();

      setState(() {
        jadwalKhusus = hasil;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat jadwal: ${e.toString()}')),
        );
      }
      debugPrint('Error fetching jadwal: $e');
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

  TimeOfDay parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    List<String> days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
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

  String formatDateForStorage(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Check if a date already has a schedule
  bool hasScheduleForDate(DateTime date) {
    String formattedDate = formatDateForStorage(date);
    return jadwalKhusus.any((jadwal) => jadwal.date == formattedDate);
  }

  // Check if date is valid (tomorrow or later)
  bool isDateValid(DateTime date) {
    DateTime today = DateTime.now();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    DateTime tomorrow = startOfToday.add(Duration(days: 1));
    
    return date.isAfter(startOfToday) || isSameDay(date, tomorrow);
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
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(icon: Icon(Icons.edit_calendar), text: 'Input Jadwal'),
            Tab(icon: Icon(Icons.calendar_view_week), text: 'Daftar Jadwal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInputJadwalTab(),
          _buildDaftarJadwalTab(),
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
                      firstDate: DateTime.now().add(Duration(days: 1)), // Start from tomorrow
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      // If not in edit mode, check if there's already a schedule for this day
                      if (editingDocId == null && hasScheduleForDate(picked)) {
                        _showAlreadyExistsDialog(picked);
                      } else {
                        setState(() => tanggalKhusus = picked);
                      }
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: "Tanggal",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                        helperText: "Pilih tanggal mulai dari besok",
                      ),
                      controller: TextEditingController(
                        text: formatTanggal(tanggalKhusus),
                      ),
                      validator: (value) {
                        if (!isDateValid(tanggalKhusus)) {
                          return 'Hanya dapat membuat jadwal untuk besok dan seterusnya';
                        }
                        return null;
                      },
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
                            validator: (value) {
                              if (!isClose && value!.isEmpty) {
                                return 'Jam mulai harus diisi';
                              }
                              return null;
                            },
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
                            validator: (value) {
                              if (!isClose && value!.isEmpty) {
                                return 'Jam selesai harus diisi';
                              }
                              if (!isClose && !isTimeValid()) {
                                return 'Jam selesai harus setelah jam mulai';
                              }
                              return null;
                            },
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
                          onPressed: _isLoading ? null : _resetForm,
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
                        onPressed: _isLoading ? null : _saveJadwal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                editingDocId != null ? "Perbarui" : "Simpan",
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

  void _resetForm() {
    setState(() {
      editingDocId = null;
      tanggalKhusus = DateTime.now().add(Duration(days: 1));
      jamMulaiKhusus = TimeOfDay(hour: 9, minute: 0);
      jamSelesaiKhusus = TimeOfDay(hour: 18, minute: 0);
      isClose = false;
    });
  }

  void _showAlreadyExistsDialog(DateTime date) {
    String formattedDate = formatDateForStorage(date);
    AllCloseDay? existingSchedule;
    
    try {
      existingSchedule = jadwalKhusus.firstWhere(
        (jadwal) => jadwal.date == formattedDate,
      );
    } catch (e) {
      // If not found, return early
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Jadwal Sudah Ada"),
        content: Text(
          "Jadwal untuk tanggal ini sudah ada. Apakah Anda ingin mengedit jadwal tersebut?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editJadwal(existingSchedule!);
            },
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: Text("Edit Jadwal"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadOrCreateSlots(DateTime selectedDate) async {
    final dateStr = formatDateForStorage(selectedDate);
    final slots = await FirebaseService().getTimeSlotsByDate(dateStr);

    if (slots.isEmpty) {
      debugPrint('Slots not exist, generating...');
      await FirebaseService().generateSlotsOneDay(selectedDate);
    }
    
    debugPrint('Closing time range slots...');
    await FirebaseService().closeUseTimeRange(
      selectedDate, // Pass DateTime instead of tanggalKhusus
      formatTime(jamMulaiKhusus),
      formatTime(jamSelesaiKhusus),
    );
  }

  bool isTimeValid() {
    int startMinutes = jamMulaiKhusus.hour * 60 + jamMulaiKhusus.minute;
    int endMinutes = jamSelesaiKhusus.hour * 60 + jamSelesaiKhusus.minute;
    return startMinutes < endMinutes;
  }

  Future<void> _saveJadwal() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation
    if (!isDateValid(tanggalKhusus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hanya dapat membuat jadwal untuk besok dan seterusnya'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If not in edit mode, check for existing schedule
    if (editingDocId == null && hasScheduleForDate(tanggalKhusus)) {
      _showAlreadyExistsDialog(tanggalKhusus);
      return;
    }

    // Time validation for time range mode
    if (!isClose && !isTimeValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jam selesai harus setelah jam mulai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // If editing, first delete the existing schedule
      if (editingDocId != null) {
        await FirebaseService().deleteCloseDay(editingDocId!);
      }

      if (isClose) {
        // Close all day
        await FirebaseService().closeAllDay(tanggalKhusus);
      } else {
        // Close specific time range
        await _loadOrCreateSlots(tanggalKhusus);
      }

      // Reset form after saving
      _resetForm();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editingDocId != null
                ? 'Jadwal berhasil diperbarui'
                : 'Jadwal berhasil disimpan',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh and switch to list tab
      await _fetchJadwalKhusus();
      _tabController.animateTo(1);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan jadwal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('Error saving jadwal: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        ? RefreshIndicator(
            onRefresh: _fetchJadwalKhusus,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Column(
                  children: [Center(child: Text("Belum ada jadwal khusus"))],
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
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(DateTime.parse(jadwal.date)),
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
                          jadwal.isClose == 'all day'
                              ? 'Tutup Sepanjang Hari'
                              : 'Jam Tutup: ${jadwal.startTime} - ${jadwal.endTime}',
                          style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                        ),
                        Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.edit, size: 18),
                              label: Text("Edit"),
                              onPressed: _isLoading ? null : () => _editJadwal(jadwal),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            TextButton.icon(
                              icon: Icon(Icons.delete, size: 18),
                              label: Text("Hapus"),
                              onPressed: _isLoading ? null : () => _showDeleteConfirmation(jadwal),
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

  void _editJadwal(AllCloseDay jadwal) {
    setState(() {
      tanggalKhusus = DateTime.parse(jadwal.date);
      if (jadwal.isClose == 'time range') {
        isClose = false;
        jamMulaiKhusus = parseTime(jadwal.startTime);
        jamSelesaiKhusus = parseTime(jadwal.endTime);
      } else if (jadwal.isClose == 'all day') {
        isClose = true;
      }
      editingDocId = jadwal.date;
    });

    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
  }

  void _showDeleteConfirmation(AllCloseDay jadwal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi Hapus"),
        content: Text(
          "Anda yakin ingin menghapus jadwal untuk ${_formatDate(DateTime.parse(jadwal.date))}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteJadwal(jadwal);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text("Hapus"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJadwal(AllCloseDay jadwal) async {
    try {
      setState(() => _isLoading = true);

      await FirebaseService().deleteCloseDay(jadwal.date);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jadwal berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _fetchJadwalKhusus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus jadwal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('Error deleting jadwal: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}