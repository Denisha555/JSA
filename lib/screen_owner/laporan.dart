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

  final memberColumns = <PlutoColumn>[
    PlutoColumn(
      title: 'Nama Member',
      field: 'nama_member',
      type: PlutoColumnType.text(),
    ),
    PlutoColumn(title: 'Kontak', field: 'kontak', type: PlutoColumnType.text()),
    PlutoColumn(title: 'Jadwal', field: 'jadwal', type: PlutoColumnType.text()),
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

                    if (_laporanData![0].status == 'nonMember') ...[
                      Expanded(
                        child: InteractiveViewer(
                          boundaryMargin: EdgeInsets.all(100),
                          minScale: 1,
                          maxScale: 2.5,
                          child: PlutoGrid(
                            columns: nonMemberColumns,
                            rows: rows,
                          ),
                        ),
                      ),
                    ] else if (_laporanData![0].status == 'member') ...[
                      Expanded(
                        child: InteractiveViewer(
                          boundaryMargin: EdgeInsets.all(100),
                          minScale: 1,
                          maxScale: 2.5,
                          child: PlutoGrid(columns: memberColumns, rows: rows),
                        ),
                      ),
                    ],
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

  void generateLaporan() async {
    _laporanSummary = _laporanData;

    if (_laporanSummary == null || _laporanSummary!.isEmpty) {
      return;
    }

    int i = 0;
    while (i <= _laporanSummary!.length - 1) {
      if (_laporanSummary!.length == 1) {
        // satu pesanan
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

        print(
          'current price : ${curr.price}, durHours: $durHours, pricePerHour: ${curr.pricePerHour}',
        );

        break;
      } else if (i == _laporanSummary!.length - 1) {
        // lebih dari satu pesanan
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

        print(
          'current price : ${curr.price}, durHours: $durHours, pricePerHour: ${curr.pricePerHour}',
        );

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
      print(
        'current price : ${curr.price}, durHours: $durHours, pricePerHour: ${curr.pricePerHour}',
      );

      i++;
    }

    // if (_laporanSummary![0].status == 'member') {
    //   for (var data in _laporanSummary!) {
    //     final username = data.username;
    //     final dates = await FirebaseGetUser().getUserData(username, 'bookingDates');
    //     final kontak = await FirebaseGetUser().getUserData(username, 'phoneNumber');

    //     List<String> bookingDates = [];
    //     List<String> courts = [];

    //   }
    // }

    setState(() {
      _laporanSummary = _laporanSummary;

      // if (_laporanSummary![0].status == 'member') {
      //   rows =
      //       _laporanSummary!.map((data) {
      //         return PlutoRow(
      //           cells: {
      //             'nama_member': PlutoCell(value: data.username),
      //             'kontak': PlutoCell(),
      //             'jadwal_main': PlutoCell(value: data.date),
      //             'total_hari': PlutoCell(value: 1),
      //             'jam': PlutoCell(
      //               value: '${data.startTime} - ${data.endTime}',
      //             ),
      //             'durasi': PlutoCell(
      //               value:
      //                   '${(timeToMinutes(data.endTime) - timeToMinutes(data.startTime)) / 60} jam',
      //             ),
      //             'lapangan': PlutoCell(value: data.courtId),
      //             'jumlah_lapangan': PlutoCell(value: 1),
      //             'harga_per_jam': PlutoCell(
      //               value: 'Rp ${data.pricePerHour.toStringAsFixed(0)}',
      //             ),
      //             'jumlah_harga': PlutoCell(
      //               value: 'Rp ${data.price.toStringAsFixed(0)}',
      //             ),
      //             'keterangan': PlutoCell(value: ""),
      //             'catatan': PlutoCell(value: ""),
      //           },
      //         );
      //       }).toList();
      // } else if (_laporanSummary![0].status == 'nonMember') {
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
        print(rows);
      // }
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
