import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';

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
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final List<Map<String, String>> statusList = [
    {'label': 'Non Member', 'value': 'nonMember'},
    {'label': 'Member', 'value': 'member'},
  ];

  String? _selectedTahun;
  String? _selectedBulan;
  String? _selectedStatus;

  final nonMemberColumns = <PlutoColumn>[
    PlutoColumn(
      title: 'Nama Pelanggan',
      field: 'nama_pelanggan',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Jadwal Main',
      field: 'jadwal_main',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Total Hari',
      field: 'total_hari',
      type: PlutoColumnType.number(),
    ),
    PlutoColumn(title: 'Jam', field: 'jam', type: PlutoColumnType.text()),
    PlutoColumn(title: 'Durasi', field: 'durasi', type: PlutoColumnType.text()),
    PlutoColumn(
      title: 'Lapangan',
      field: 'lapangan',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Jumlah Lapangan',
      field: 'jumlah_lapangan',
      type: PlutoColumnType.number(),
    ),
    PlutoColumn(
      title: 'Harga per Jam',
      field: 'harga_per_jam',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Jumlah Harga',
      field: 'jumlah_harga',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Keterangan',
      field: 'keterangan',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Catatan',
      field: 'catatan',
      type: PlutoColumnType.text(),
    ),
  ];

  final memberColumns = <PlutoColumn>[
    PlutoColumn(
      title: 'Nama Member',
      field: 'nama_member',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(title: 'Kontak', field: 'kontak', type: PlutoColumnType.text()),
    PlutoColumn(
      title: 'Jadwal Main',
      field: 'jadwal_main',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Total Hari',
      field: 'total_hari',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(title: 'Jam', field: 'jam', type: PlutoColumnType.text()),
    PlutoColumn(title: 'Durasi', field: 'durasi', type: PlutoColumnType.text()),
    PlutoColumn(
      title: 'Lapangan',
      field: 'lapangan',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Jumlah Lapangan',
      field: 'jumlah_lapangan',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Harga per Jam',
      field: 'harga_per_jam',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Jumlah Harga',
      field: 'jumlah_harga',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Keterangan',
      field: 'keterangan',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(
      title: 'Catatan',
      field: 'catatan',
      type: PlutoColumnType.text(),
    ),
  ];

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
  }

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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
                                width:
                                    MediaQuery.of(context).size.width / 2 - 55,
                                height: 50,
                                child: DropdownButton(
                                  hint: const Text('Pilih Tahun'),
                                  isExpanded: true,
                                  value: _selectedTahun,
                                  items:
                                      tahunList.map((String item) {
                                        return DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(item),
                                        );
                                      }).toList(),
                                  onChanged:
                                      _isLoading
                                          ? null
                                          : (String? value) {
                                            setState(() {
                                              _selectedTahun = value;
                                            });
                                          },
                                ),
                              ),

                              const SizedBox(width: 15),

                              SizedBox(
                                height: 50,
                                width:
                                    MediaQuery.of(context).size.width / 2 - 55,
                                child: DropdownButton(
                                  hint: const Text('Pilih Bulan'),
                                  isExpanded: true,
                                  value: _selectedBulan,
                                  items:
                                      bulanList.map((String item) {
                                        return DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(item),
                                        );
                                      }).toList(),
                                  onChanged:
                                      _isLoading
                                          ? null
                                          : (String? value) {
                                            setState(() {
                                              _selectedBulan = value;
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
                                  statusList.map((Map<String, String> item) {
                                    return DropdownMenuItem<String>(
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
                              icon:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Icon(Icons.bar_chart),
                              label: Text(
                                _isLoading ? 'Memuat...' : 'Tampilkan Laporan',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                ],
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
                                _zoomScale == 1.0 ? null : () => _resetZoom(),
                          ),
                        ],
                      ),
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
                              for (var col in _stateManager!.columns) {
                                final originalWidth =
                                    _originalColumnWidths[col.field];
                                if (originalWidth != null) {
                                  col.width = (originalWidth * _zoomScale)
                                      .clamp(40.0, double.infinity);
                                }
                              }
                              _stateManager!.notifyListeners();
                            }
                          },
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

  void generateLaporan() async {
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

      _laporanSummary = result;
    }

    // Reset zoom setiap kali generate laporan baru
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
              'jumlah_lapangan': PlutoCell(value: 1),
              'harga_per_jam': PlutoCell(
                value: 'Rp ${data.pricePerHour.toStringAsFixed(0)}',
              ),
              'jumlah_harga': PlutoCell(
                value: 'Rp ${data.price.toStringAsFixed(0)}',
              ),
              'keterangan': PlutoCell(value: ""),
              'catatan': PlutoCell(value: ""),
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
                  'jumlah_lapangan': PlutoCell(value: 1),
                  'harga_per_jam': PlutoCell(
                    value: 'Rp ${data.pricePerHour.toStringAsFixed(0)}',
                  ),
                  'jumlah_harga': PlutoCell(
                    value: 'Rp ${data.price.toStringAsFixed(0)}',
                  ),
                  'keterangan': PlutoCell(value: ""),
                  'catatan': PlutoCell(value: ""),
                },
              );
            }).toList();
      }
    });
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
        _selectedStatus!,
      );

      setState(() {
        _laporanData = data;
        _isLoading = false;
      });

      generateLaporan();
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
}
