import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';
import 'package:pluto_grid/pluto_grid.dart';

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  bool _isLoading = false;

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

  final columns = <PlutoColumn>[
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
                                  hint: Text('Pilih Tahun'),
                                  isExpanded: true,
                                  value: _selectedTahun,
                                  items:
                                      tahunList.map((String item) {
                                        return DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(item),
                                        );
                                      }).toList(),
                                  onChanged: (String? value) {
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
                                  hint: Text('Pilih Bulan'),
                                  isExpanded: true,
                                  value: _selectedBulan,
                                  items:
                                      bulanList.map((String item) {
                                        return DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(item),
                                        );
                                      }).toList(),
                                  onChanged: (String? value) {
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
                              hint: Text('Pilih Status'),
                              isExpanded: true,
                              value: _selectedStatus,
                              items:
                                  statusList.map((Map<String, String> item) {
                                    return DropdownMenuItem<String>(
                                      value: item['value'],
                                      child: Text(item['label']!),
                                    );
                                  }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tombol Generate Laporan
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                _isLoading ? null : await _getLaporan();
                              },
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

                    Expanded(
                      child: InteractiveViewer(
                        boundaryMargin: EdgeInsets.all(100),
                        minScale: 1,
                        maxScale: 2.5,
                        child: PlutoGrid(columns: columns, rows: rows),
                      ),
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
                            'Pilih periode waktu untuk melihat laporan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
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

  bool canMerge(a, b) =>
      a.username == b.username &&
      a.date == b.date &&
      a.courtId == b.courtId &&
      a.endTime == b.startTime;

  void generateLaporan() {
    // _laporanSummary = List<TimeSlotModel>.from(_laporanData!);

    // int i = 0;
    // final result = List<TimeSlotModel>.from(_laporanSummary!);
    // for (var item in _laporanSummary!) {
    //   var _laporanData![i] = _laporanSummary![i];
    //   var _laporanData![i + 1] = _laporanSummary![i + 1];
    //   if (result.isNotEmpty && canMerge(result.last, item)) {
    //     _laporanData![i].endTime = _laporanData![i + 1].endTime;
    //     _laporanData![i].price += _laporanData![i + 1].price;
    //   } else {
    //     result.add(item);
    //   }

    //   final durMinutes =
    //       timeToMinutes(_laporanData![i].endTime) - timeToMinutes(_laporanData![i].startTime);

    //   final durHours = durMinutes / 60.0;
    //   _laporanData![i].pricePerHour = durHours > 0 ? _laporanData![i].price / durHours : _laporanData![i].price;
    // }

    // _laporanSummary = result;

    _laporanSummary = [];

    int i = 0;
    while (i < _laporanData!.length - 1) {
      int start = 0;
      int end = 0;
      if (_laporanData![i].username == _laporanData![i + 1].username &&
          _laporanData![i].date == _laporanData![i + 1].date &&
          _laporanData![i].courtId == _laporanData![i + 1].courtId &&
          _laporanData![i].endTime == _laporanData![i + 1].startTime) {
        end = end + 1;
        continue;
      } else {
        _laporanSummary!.add(_laporanData![start]);
        _laporanSummary![start].endTime = _laporanData![end].endTime;
        _laporanSummary![start].price = _laporanSummary![start].price * (end - start + 1);
      }
      
      final durHours =
          ((timeToMinutes(_laporanData![i].endTime) - timeToMinutes(_laporanData![i].startTime)) ~/ 60);
      _laporanData![i].pricePerHour = durHours >= 1 ? _laporanData![i].price / durHours : _laporanData![i].price;

      i++;
      start = end;
    }

    setState(() {
      _laporanSummary = _laporanSummary;

      rows =
          _laporanSummary!.map((data) {
            return PlutoRow(
              cells: {
                'nama_pelanggan': PlutoCell(value: data.username),
                'jadwal_main': PlutoCell(value: data.date),
                'total_hari': PlutoCell(value: 1),
                'jam': PlutoCell(value: '${data.startTime} - ${data.endTime}'),
                'durasi': PlutoCell(
                  value:
                      '${(timeToMinutes(data.endTime) - timeToMinutes(data.startTime)) ~/ 60} jam',
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
    });
  }

  Future<void> _getLaporan() async {
    setState(() {
      _isLoading = true;
    });

    final data = await FirebaseGetBooking().getBookingForReport(
      "$_selectedTahun-${(bulanList.indexOf(_selectedBulan!) + 1).toString().padLeft(2, '0')}",
      _selectedStatus!,
    );

    print('Laporan data: ${data.length} slots');

    setState(() {
      _laporanData = data;
      _isLoading = false;
    });

    generateLaporan();
  }
}
