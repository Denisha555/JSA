import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';
import 'package:flutter_application_1/services/time_slot/firebase_update_time_slot.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  bool _isLoading = false;
  Key _gridKey = UniqueKey();

  List<TimeSlotModel>? _laporanData;
  List<TimeSlotModel>? _laporanSummary;

  List<String> tahunList = [
    for (var i = 2020; i <= DateTime.now().year; i++) i.toString(),
  ];
  List<String> bulanList = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  final List<Map<String, String>> statusList = [
    {'label': 'Non Member', 'value': 'nonMember'},
    {'label': 'Member', 'value': 'member'},
  ];

  bool _isEditing = false;

  String? _selectedTahun;
  String? _selectedBulan;
  String? _selectedStatus;

  late List<PlutoColumn> nonMemberColumns;
  late List<PlutoColumn> memberColumns;

  List<PlutoRow> rows = [];

  PlutoGridStateManager? _stateManager;
  double _zoomScale = 1.0;

  final double _minZoom = 0.7;
  final double _maxZoom = 1.8;

  // Lebar awal kolom disimpan supaya zoom tidak drift
  final Map<String, double> _originalColumnWidths = {};

  double _previousScale = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedTahun = DateTime.now().year.toString();
    _selectedBulan = bulanList[DateTime.now().month - 1];
    _selectedStatus = statusList[0]['value'];
    _getLaporan();
    _initColumns();
  }

  void _initColumns() {
    nonMemberColumns = <PlutoColumn>[
      PlutoColumn(
        title: 'Nama Pelanggan',
        field: 'nama_pelanggan',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('nama_pelanggan', 'Nama Pelanggan'),
      ),
      PlutoColumn(
        title: 'Jadwal Main',
        field: 'jadwal_main',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('jadwal_main', 'Jadwal Main'),
      ),
      PlutoColumn(
        title: 'Total Hari',
        field: 'total_hari',
        type: PlutoColumnType.number(),
        readOnly: true,
        width: _calcColumnWidth('total_hari', 'Total Hari'),
      ),
      PlutoColumn(
        title: 'Jam',
        field: 'jam',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('jam', 'Jam'),
      ),
      PlutoColumn(
        title: 'Durasi',
        field: 'durasi',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('durasi', 'Durasi'),
      ),
      PlutoColumn(
        title: 'Lapangan',
        field: 'lapangan',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('lapangan', 'Lapangan'),
      ),
      PlutoColumn(
        title: 'Harga per Jam',
        field: 'harga_per_jam',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('harga_per_jam', 'Harga per Jam'),
      ),
      PlutoColumn(
        title: 'Jumlah Harga',
        field: 'jumlah_harga',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('jumlah_harga', 'Jumlah Harga'),
      ),
      PlutoColumn(
        title: 'Keterangan',
        field: 'keterangan',
        type: PlutoColumnType.text(),
        readOnly: _isEditing ? false : true,
        width: _calcColumnWidth('keterangan', 'Keterangan'),
      ),
      PlutoColumn(
        title: 'Catatan',
        field: 'catatan',
        type: PlutoColumnType.text(),
        readOnly: _isEditing ? false : true,
        width: _calcColumnWidth('catatan', 'Catatan'),
      ),
    ];

    memberColumns = <PlutoColumn>[
      PlutoColumn(
        title: 'Nama Member',
        field: 'nama_member',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('nama_member', 'Nama Member'),
      ),
      PlutoColumn(
        title: 'Kontak',
        field: 'kontak',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('kontak', 'Kontak'),
      ),
      PlutoColumn(
        title: 'Jadwal Main',
        field: 'jadwal_main',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('jadwal_main', 'Jadwal Main'),
      ),
      PlutoColumn(
        title: 'Total Hari',
        field: 'total_hari',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('total_hari', 'Total Hari'),
      ),
      PlutoColumn(
        title: 'Jam',
        field: 'jam',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('jam', 'Jam'),
      ),
      PlutoColumn(
        title: 'Durasi',
        field: 'durasi',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('durasi', 'Durasi'),
      ),
      PlutoColumn(
        title: 'Lapangan',
        field: 'lapangan',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('lapangan', 'Lapangan'),
      ),
      PlutoColumn(
        title: 'Harga per Jam',
        field: 'harga_per_jam',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('harga_per_jam', 'Harga per Jam'),
      ),
      PlutoColumn(
        title: 'Jumlah Harga',
        field: 'jumlah_harga',
        type: PlutoColumnType.text(),
        readOnly: true,
        width: _calcColumnWidth('jumlah_harga', 'Jumlah Harga'),
      ),
      PlutoColumn(
        title: 'Keterangan',
        field: 'keterangan',
        type: PlutoColumnType.text(),
        readOnly: _isEditing ? false : true,
        width: _calcColumnWidth('keterangan', 'Keterangan'),
      ),
      PlutoColumn(
        title: 'Catatan',
        field: 'catatan',
        type: PlutoColumnType.text(),
        readOnly: _isEditing ? false : true,
        width: _calcColumnWidth('catatan', 'Catatan'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Memuat data..."),
                  ],
                ),
              )
              : Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16,
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder:
                            (child, animation) => SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _isEditing
                                ? SizedBox.shrink(key: ValueKey('hidden'))
                                : Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.width /
                                                      2 -
                                                  55,
                                              height: 50,
                                              child: DropdownButton(
                                                hint: const Text('Pilih Tahun'),
                                                isExpanded: true,
                                                value: _selectedTahun,
                                                items:
                                                    tahunList.map((
                                                      String item,
                                                    ) {
                                                      return DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: item,
                                                        child: Text(item),
                                                      );
                                                    }).toList(),
                                                onChanged:
                                                    _isLoading
                                                        ? null
                                                        : (String? value) {
                                                          setState(() {
                                                            _selectedTahun =
                                                                value;
                                                          });
                                                        },
                                              ),
                                            ),

                                            const SizedBox(width: 15),

                                            SizedBox(
                                              height: 50,
                                              width:
                                                  MediaQuery.of(
                                                        context,
                                                      ).size.width /
                                                      2 -
                                                  55,
                                              child: DropdownButton(
                                                hint: const Text('Pilih Bulan'),
                                                isExpanded: true,
                                                value: _selectedBulan,
                                                items:
                                                    bulanList.map((
                                                      String item,
                                                    ) {
                                                      return DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: item,
                                                        child: Text(item),
                                                      );
                                                    }).toList(),
                                                onChanged:
                                                    _isLoading
                                                        ? null
                                                        : (String? value) {
                                                          setState(() {
                                                            _selectedBulan =
                                                                value;
                                                          });
                                                        },
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        SizedBox(
                                          height: 50,
                                          width: double.infinity,
                                          child: DropdownButton(
                                            hint: const Text('Pilih Status'),
                                            isExpanded: true,
                                            value: _selectedStatus,
                                            items:
                                                statusList.map((
                                                  Map<String, String> item,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: item['value'],
                                                    child: Text(item['label']!),
                                                  );
                                                }).toList(),
                                            onChanged:
                                                _isLoading
                                                    ? null
                                                    : (String? value) {
                                                      setState(() {
                                                        _selectedStatus = value;
                                                      });
                                                    },
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            // ← pakai null langsung kalau loading, bukan fungsi kosong
                                            onPressed:
                                                _isLoading
                                                    ? null
                                                    : () async {
                                                      await _getLaporan();
                                                    },

                                            label: Text(
                                              _isLoading
                                                  ? 'Memuat...'
                                                  : 'Tampilkan Laporan',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                      ),
                    ),

                    SliverFillRemaining(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          if (_laporanSummary != null &&
                              _laporanSummary!.isNotEmpty) ...[
                            const Text(
                              'Hasil Laporan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_laporanSummary![0].type == 'nonMember' ||
                                _laporanSummary![0].type == 'member') ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Tombol zoom out: disable kalau sudah mentok minimum
                                  IconButton(
                                    icon: const Icon(Icons.zoom_out),
                                    onPressed:
                                        _zoomScale <= _minZoom
                                            ? null
                                            : () => _zoomGrid(0.9),
                                  ),
                                  Text('${(_zoomScale * 100).round()}%'),
                                  // Tombol zoom in: disable kalau sudah mentok maximum
                                  IconButton(
                                    icon: const Icon(Icons.zoom_in),
                                    onPressed:
                                        _zoomScale >= _maxZoom
                                            ? null
                                            : () => _zoomGrid(1.1),
                                  ),
                                  // Tombol reset zoom
                                  IconButton(
                                    icon: const Icon(Icons.zoom_out_map),
                                    tooltip: 'Reset Zoom',
                                    onPressed:
                                        _zoomScale == 1.0
                                            ? null
                                            : () => _resetZoom(),
                                  ),
                                  IconButton(
                                    tooltip: 'Export xlsx',
                                    onPressed: () async {
                                      if ((_laporanSummary == null ||
                                          _laporanSummary!.isEmpty)) {
                                        return;
                                      } else {
                                        print("export to excel");
                                        await exportToExcel();
                                      }
                                    },
                                    icon: Icon(Icons.download),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: PlutoGrid(
                                        key: _gridKey,
                                        columns:
                                            _laporanSummary![0].type == 'member'
                                                ? memberColumns
                                                : nonMemberColumns,
                                        rows: rows,
                                        onLoaded: (event) {
                                          _stateManager = event.stateManager;

                                          // Kalau originalWidths belum ada, simpan (hanya pertama kali)
                                          if (_originalColumnWidths.isEmpty) {
                                            _saveOriginalWidths();
                                          } else {
                                            // Grid rebuild karena zoom — terapkan ulang lebar sesuai scale
                                            for (var col
                                                in _stateManager!.columns) {
                                              final originalWidth =
                                                  _originalColumnWidths[col
                                                      .field];
                                              if (originalWidth != null) {
                                                col.width = (originalWidth *
                                                        _zoomScale)
                                                    .clamp(
                                                      40.0,
                                                      double.infinity,
                                                    );
                                              }
                                            }
                                            _stateManager!.notifyListeners();
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading
                                                ? null
                                                : () async {
                                                  if (_isEditing) {
                                                    try {
                                                      _stateManager?.setEditing(
                                                        false,
                                                      );
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus();

                                                      await Future.delayed(
                                                        const Duration(
                                                          milliseconds: 50,
                                                        ),
                                                      );

                                                      setState(() {
                                                        _isEditing = false;
                                                        _isLoading = true;
                                                      });
                                                      for (final column
                                                          in _stateManager!
                                                              .columns) {
                                                        if (column.field ==
                                                                'catatan' ||
                                                            column.field ==
                                                                'keterangan') {
                                                          column.readOnly =
                                                              true;
                                                        }
                                                      }

                                                      _stateManager!
                                                          .notifyListeners();

                                                      final rows =
                                                          _stateManager!.rows;

                                                      final futures =
                                                          <Future>[];
                                                      for (var row in rows) {
                                                        final username =
                                                            row.cells.containsKey(
                                                                  '_username',
                                                                )
                                                                ? row
                                                                    .cells['_username']!
                                                                    .value
                                                                    .toString()
                                                                : row
                                                                    .cells['nama_pelanggan']!
                                                                    .value
                                                                    .toString();
                                                        final court =
                                                            row
                                                                .cells['lapangan']!
                                                                .value;
                                                        dynamic date =
                                                            row
                                                                .cells['jadwal_main']!
                                                                .value;
                                                        final startTime =
                                                            row
                                                                .cells['jam']!
                                                                .value
                                                                .split(
                                                                  ' - ',
                                                                )[0];
                                                        final endTime =
                                                            row
                                                                .cells['jam']!
                                                                .value
                                                                .split(
                                                                  ' - ',
                                                                )[1];
                                                        final catatan =
                                                            row
                                                                .cells['catatan']!
                                                                .value;
                                                        final keterangan =
                                                            row
                                                                .cells['keterangan']!
                                                                .value;

                                                        if (row.cells
                                                            .containsKey(
                                                              '_username',
                                                            )) {
                                                          String jadwal =
                                                              row
                                                                  .cells['jadwal_main']!
                                                                  .value
                                                                  .toString();
                                                          String insideBracket =
                                                              jadwal
                                                                  .split('(')[1]
                                                                  .replaceAll(
                                                                    ')',
                                                                    '',
                                                                  )
                                                                  .trim();
                                                          List<String> date =
                                                              insideBracket
                                                                  .split(', ')
                                                                  .map(
                                                                    (e) =>
                                                                        e.trim(),
                                                                  )
                                                                  .toList();
                                                          for (var d in date) {
                                                            futures.add(
                                                              FirebaseUpdateTimeSlot()
                                                                  .updateReportTimeSlots(
                                                                    username,
                                                                    d,
                                                                    court,
                                                                    startTime,
                                                                    endTime,
                                                                    catatan,
                                                                    keterangan,
                                                                  ),
                                                            );
                                                          }
                                                        } else {
                                                          futures.add(
                                                            FirebaseUpdateTimeSlot()
                                                                .updateReportTimeSlots(
                                                                  username,
                                                                  date,
                                                                  court,
                                                                  startTime,
                                                                  endTime,
                                                                  catatan,
                                                                  keterangan,
                                                                ),
                                                          );
                                                        }
                                                      }
                                                      await Future.wait(
                                                        futures,
                                                      );

                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                      showSuccessSnackBar(
                                                        context,
                                                        "Perubahan berhasil disimpan",
                                                      );
                                                    } catch (e) {
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                      showErrorSnackBar(
                                                        context,
                                                        "Gagal menyimpan perubahan: $e",
                                                      );
                                                      print(e);
                                                    }
                                                  } else {
                                                    // Ubah ke mode edit
                                                    setState(() {
                                                      _isEditing = true;
                                                    });

                                                    for (final column
                                                        in _stateManager!
                                                            .columns) {
                                                      if (column.field ==
                                                              'catatan' ||
                                                          column.field ==
                                                              'keterangan') {
                                                        column.readOnly = false;
                                                      }
                                                    }

                                                    // Force PlutoGrid rebuild columns
                                                    _stateManager!
                                                        .notifyListeners();
                                                  }
                                                },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 24,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child:
                                            _isEditing
                                                ? Text("Simpan Perubahan")
                                                : Text("Edit Laporan"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ] else if (_isLoading) ...[
                            const Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Memuat laporan...'),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            const Expanded(
                              child: Center(child: Text("Data Tidak Tersedia")),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  /// Simpan lebar asli kolom sebagai referensi zoom
  void _saveOriginalWidths() {
    // if (_stateManager == null) return;
    // _originalColumnWidths.clear();
    for (var col in _stateManager!.columns) {
      _originalColumnWidths[col.field] = col.width;
    }
  }

  void _zoomGrid(double factor) {
    if (_stateManager == null) return;

    final newScale = (_zoomScale * factor).clamp(_minZoom, _maxZoom);
    if (newScale == _zoomScale) return;

    // Terapkan width dulu ke originalColumnWidths-scaled sebelum rebuild
    _zoomScale = newScale;

    // Reset scroll ke awal supaya tidak ada kolom yang hilang
    _stateManager!.scroll.horizontal?.jumpTo(0);

    for (var col in _stateManager!.columns) {
      final originalWidth = _originalColumnWidths[col.field];
      if (originalWidth != null) {
        final newWidth = (originalWidth * _zoomScale).clamp(
          40.0,
          double.infinity,
        );
        col.width = newWidth;
      }
    }

    setState(() {
      _gridKey = UniqueKey(); // ← force rebuild grid
    });
  }

  void _resetZoom() {
    if (_stateManager == null) return;

    _zoomScale = 1.0;
    _stateManager!.scroll.horizontal?.jumpTo(0);

    setState(() {
      _gridKey = UniqueKey();
    });
  }

  Future<void> generateLaporan() async {
    _zoomScale = 1.0;
    _originalColumnWidths.clear();

    _laporanSummary = _laporanData;

    if (_laporanSummary == null || _laporanSummary!.isEmpty) {
      setState(() {});
      return;
    }

    int i = 0;
    while (i <= _laporanSummary!.length - 1) {
      if (_laporanSummary!.length == 1) {
        final curr = _laporanSummary![i];
        final durHours =
            ((timeToMinutes(curr.endTime) - timeToMinutes(curr.startTime)) /
                60);
        if (durHours.round() % durHours != 0) {
          int slots = durHours.round() + 1;
          double pricePerSlot = curr.price / slots;
          curr.pricePerHour = pricePerSlot * 2;
        } else {
          curr.pricePerHour = (curr.price / durHours);
        }
        break;
      } else if (i == _laporanSummary!.length - 1) {
        final curr = _laporanSummary![i];
        final prev = _laporanSummary![i - 1];

        if (curr.username == prev.username &&
            curr.date == prev.date &&
            curr.courtId == prev.courtId &&
            timeToMinutes(curr.startTime) == timeToMinutes(prev.endTime)) {
          prev.endTime = curr.endTime;
          prev.price += curr.price;
          _laporanSummary!.removeAt(i);
        }

        final durHours =
            ((timeToMinutes(curr.endTime) - timeToMinutes(curr.startTime)) /
                60);
        if (durHours.round() % durHours != 0) {
          int slots = durHours.round() + 1;
          double pricePerSlot = curr.price / slots;
          curr.pricePerHour = pricePerSlot * 2;
        } else {
          curr.pricePerHour = (curr.price / durHours);
        }
        break;
      }

      var curr = _laporanSummary![i];
      var next = _laporanSummary![i + 1];

      if (curr.username == next.username &&
          curr.date == next.date &&
          curr.courtId == next.courtId &&
          timeToMinutes(curr.endTime) == timeToMinutes(next.startTime)) {
        curr.endTime = next.endTime;
        curr.price += next.price;
        _laporanSummary!.removeAt(i + 1);
        continue;
      }

      final durHours =
          ((timeToMinutes(curr.endTime) - timeToMinutes(curr.startTime)) / 60);
      if (durHours.round() % durHours != 0) {
        int slots = durHours.round() + 1;
        double pricePerSlot = curr.price / slots;
        curr.pricePerHour = pricePerSlot * 2;
      } else {
        curr.pricePerHour = (curr.price / durHours);
      }

      i++;
    }

    if (_laporanSummary![0].type == 'member') {
      Map<String, List<TimeSlotModel>> grouped = {};

      for (var data in _laporanSummary!) {
        String key =
            '${data.username}_${data.courtId}_${data.startTime}_${data.endTime}';
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(data);
      }

      List<TimeSlotModel> result = [];

      for (var entry in grouped.entries) {
        List<TimeSlotModel> group = entry.value;
        TimeSlotModel first = group[0];

        List<String> allDates = group.map((e) => e.date).toList();

        Set<String> uniqueDays = {};
        for (var dateStr in allDates) {
          final date = DateTime.parse(dateStr);
          final day = namaHari(date.weekday);
          uniqueDays.add(day);
        }

        String datesStr = allDates.map((d) => d.split("-")[2]).join(', ');

        if (uniqueDays.length == 1) {
          first.jadwal = "${uniqueDays.first} ($datesStr)";
        } else {
          String allDays = uniqueDays.join(', ');
          first.jadwal = "$allDays ($datesStr)";
        }

        first.totalHari = allDates.length;

        if (first.kontak == null || first.kontak.isEmpty) {
          final kontak = await FirebaseGetUser().getUserData(
            first.username,
            'phoneNumber',
          );
          first.kontak = kontak;
        }

        result.add(first);
      }

      for (var data in result) {
        data.price = data.pricePerHour * ((timeToMinutes(data.endTime) - timeToMinutes(data.startTime)) / 30) * data.totalHari;
      }

      _laporanSummary = result;
    }

    _zoomScale = 1.0;
    _originalColumnWidths.clear();

    setState(() {
      _gridKey = UniqueKey();

      if (_laporanSummary![0].type == 'member') {
        rows = List.generate(_laporanSummary!.length, (index) {
          final data = _laporanSummary![index];
          // Nama hanya tampil di row pertama per username,
          // row berikutnya kosong supaya terkesan seperti di-merge
          final showNama =
              index == 0 ||
              _laporanSummary![index - 1].username != data.username;
          return PlutoRow(
            cells: {
              'nama_member': PlutoCell(value: showNama ? data.username : ''),
              'kontak': PlutoCell(value: showNama ? (data.kontak ?? '') : ''),
              'jadwal_main': PlutoCell(value: data.jadwal),
              'total_hari': PlutoCell(value: data.totalHari),
              'jam': PlutoCell(value: '${data.startTime} - ${data.endTime}'),
              'durasi': PlutoCell(
                value:
                    '${(timeToMinutes(data.endTime) - timeToMinutes(data.startTime)) / 60} jam',
              ),
              'lapangan': PlutoCell(value: data.courtId),
              'harga_per_jam': PlutoCell(
                value: 'Rp ${data.pricePerHour.toStringAsFixed(0)}',
              ),
              'jumlah_harga': PlutoCell(
                value: 'Rp ${data.price.toStringAsFixed(0)}',
              ),
              'keterangan': PlutoCell(value: data.keterangan ?? ""),
              'catatan': PlutoCell(value: data.catatan ?? ""),
              '_username': PlutoCell(value: data.username),
            },
          );
        });
      } else if (_laporanSummary![0].type == 'nonMember') {
        rows =
            _laporanSummary!.map((data) {
              return PlutoRow(
                cells: {
                  'nama_pelanggan': PlutoCell(value: data.username),
                  'jadwal_main': PlutoCell(value: data.date),
                  'total_hari': PlutoCell(value: 1),
                  'jam': PlutoCell(
                    value: '${data.startTime} - ${data.endTime}',
                  ),
                  'durasi': PlutoCell(
                    value:
                        '${(timeToMinutes(data.endTime) - timeToMinutes(data.startTime)) / 60} jam',
                  ),
                  'lapangan': PlutoCell(value: data.courtId),
                  'harga_per_jam': PlutoCell(
                    value: 'Rp ${data.pricePerHour.toStringAsFixed(0)}',
                  ),
                  'jumlah_harga': PlutoCell(
                    value: 'Rp ${data.price.toStringAsFixed(0)}',
                  ),
                  'keterangan': PlutoCell(value: data.keterangan ?? ""),
                  'catatan': PlutoCell(value: data.catatan ?? ""),
                },
              );
            }).toList();
      }
    });
  }

  double _calcColumnWidth(String field, String header) {
    // Mulai dari panjang header
    double maxLen = header.length.toDouble();

    for (final row in rows) {
      final value = row.cells[field]?.value?.toString() ?? '';
      if (value.length > maxLen) {
        maxLen = value.length.toDouble();
      }
    }

    // Setiap karakter ~8px, tambah padding, min 80, max 300
    return (maxLen * 8.0 + 40.0).clamp(80.0, 300.0);
  }

  Future<void> _getLaporan() async {
    setState(() {
      _isLoading = true;
      // Reset data lama supaya tidak tampil grid lama saat loading
      _laporanSummary = null;
      rows = [];
    });

    try {
      final data = await FirebaseGetBooking().getBookingForReport(
        "$_selectedTahun-${(bulanList.indexOf(_selectedBulan!) + 1).toString().padLeft(2, '0')}",
        "$_selectedTahun-${(bulanList.indexOf(_selectedBulan!) + 2).toString().padLeft(2, '0')}",
        _selectedStatus!,
      );

      setState(() {
        _laporanData = data;
      });

      await generateLaporan();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _laporanData = [];
        _laporanSummary = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> downloadFile(List<int> bytes, String fileName) async {
    Directory? saveDir;

    if (Platform.isAndroid) {
      // Minta izin storage
      PermissionStatus status;

      if (await _isAndroid13OrAbove()) {
        // Android 13+ tidak perlu izin storage untuk Downloads
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
      }

      if (status.isDenied || status.isPermanentlyDenied) {
        throw Exception('Izin penyimpanan ditolak');
      }

      // Simpan ke folder Downloads
      saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) {
        saveDir = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      // iOS: simpan ke Documents (bisa diakses via Files app)
      saveDir = await getApplicationDocumentsDirectory();
    }

    if (saveDir == null) {
      throw Exception('Tidak bisa menemukan folder penyimpanan');
    }

    final file = File('${saveDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return file.path; // return path supaya bisa tampilkan notifikasi
  }

  Future<bool> _isAndroid13OrAbove() async {
    if (!Platform.isAndroid) return false;
    // Android 13 = SDK 33
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      final sdk = int.tryParse(result.stdout.toString().trim()) ?? 0;
      return sdk >= 33;
    } catch (_) {
      return false;
    }
  }

  Future<void> exportToExcel() async {
    if (_laporanSummary == null || _laporanSummary!.isEmpty) return;

    final excel = Excel.createExcel();
    final Sheet sheet =
        excel['Laporan ${_selectedStatus} ${_selectedBulan} $_selectedTahun'];
    excel.delete('Sheet1');

    final bool isMember = _laporanSummary![0].type == 'member';

    final List<String> headers =
        isMember
            ? [
              'Nama Member',
              'Kontak',
              'Jadwal Main',
              'Total Hari',
              'Jam',
              'Durasi',
              'Lapangan',
              'Harga per Jam',
              'Jumlah Harga',
              'Keterangan',
              'Catatan',
            ]
            : [
              'Nama Pelanggan',
              'Jadwal Main',
              'Total Hari',
              'Jam',
              'Durasi',
              'Lapangan',
              'Harga per Jam',
              'Jumlah Harga',
              'Keterangan',
              'Catatan',
            ];

    final List<String> fields =
        isMember
            ? [
              'nama_member',
              'kontak',
              'jadwal_main',
              'total_hari',
              'jam',
              'durasi',
              'lapangan',
              'harga_per_jam',
              'jumlah_harga',
              'keterangan',
              'catatan',
            ]
            : [
              'nama_pelanggan',
              'jadwal_main',
              'total_hari',
              'jam',
              'durasi',
              'lapangan',
              'harga_per_jam',
              'jumlah_harga',
              'keterangan',
              'catatan',
            ];

    // --- Judul laporan ---
    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    titleCell.value = TextCellValue(
      'LAPORAN ${_selectedStatus!.toUpperCase()} ${_selectedBulan!.toUpperCase()} $_selectedTahun',
    );
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Left,
    );

    // --- Header kolom (row index 1) ---
    final CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1E40AF'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (int col = 0; col < headers.length; col++) {
      // ← fix: hapus +1
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1),
      );
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // --- Data rows (mulai row index 2) ---
    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      final row = rows[rowIdx];
      final CellStyle rowStyle = CellStyle(
        backgroundColorHex:
            rowIdx % 2 == 0
                ? ExcelColor.fromHexString('#EFF6FF')
                : ExcelColor.fromHexString('#FFFFFF'),
      );

      for (int col = 0; col < fields.length; col++) {
        final value = row.cells[fields[col]]?.value?.toString() ?? '';
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: col,
            rowIndex: rowIdx + 2,
          ), // ← fix: +2 karena header di row 1
        );
        cell.value = TextCellValue(value);
        cell.cellStyle = rowStyle;
      }
    }

    // --- Auto column width berdasarkan konten ---
    for (int col = 0; col < headers.length; col++) {
      double maxLen = headers[col].length.toDouble();

      for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
        final value = rows[rowIdx].cells[fields[col]]?.value?.toString() ?? '';
        if (value.length > maxLen) maxLen = value.length.toDouble();
      }

      sheet.setColumnWidth(col, (maxLen + 4).clamp(10.0, 50.0));
    }

    // --- Simpan file ---
    final bytes = excel.encode();
    if (bytes == null) return;

    final fileName =
        'Laporan_${_selectedStatus}_${_selectedBulan}_${_selectedTahun}.xlsx';

    try {
      final path = await downloadFile(bytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File tersimpan: $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
