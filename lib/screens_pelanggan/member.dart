import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HalamanMember extends StatefulWidget {
  const HalamanMember({super.key});

  @override
  State<HalamanMember> createState() => _HalamanMemberState();
}

List<DateTime> getWeekdaysInRange(int weekday, DateTime baseDate) {
  final endDate = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);

  return List.generate(
    endDate.difference(baseDate).inDays + 5,
    (i) => baseDate.add(Duration(days: i)),
  ).where((d) => d.weekday == weekday).toList();
}

class _HalamanMemberState extends State<HalamanMember> {
  String selectedDuration = '2';
  int? selectedWeekday;
  List<DateTime> selectedDates = [];

  final Map<String, int> weekdayMap = {
    'Senin': 1,
    'Selasa': 2,
    'Rabu': 3,
    'Kamis': 4,
    'Jumat': 5,
    'Sabtu': 6,
    'Minggu': 7,
  };

  String _formatDate(DateTime date) {
    List<String> months = [
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
    List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentDate = now; 

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            const Text('Pilih Hari'),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    weekdayMap.keys.map((day) {
                      final isSelected = weekdayMap[day] == selectedWeekday;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(
                            day,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.blue,
                          onSelected: (_) {
                            setState(() {
                              selectedWeekday = weekdayMap[day];
                              selectedDates = getWeekdaysInRange(
                                selectedWeekday!,
                                currentDate,
                              ); 
                            });
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Durasi'),
            const SizedBox(height: 10),
            SizedBox(
              width: 150,
              child: DropdownButton<String>(
                value: selectedDuration,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    selectedDuration = value!;
                  });
                },
                items: [
                  for (var i = 2; i <= 6; i++)
                    DropdownMenuItem(
                      value: i.toString(),
                      child: Text('$i jam'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (selectedDates.isNotEmpty) const Text('Tanggal yang dipilih:'),
            Expanded(
              child: ListView.builder(
                itemCount: selectedDates.length,
                itemBuilder: (context, index) {
                  final date = selectedDates[index];
                  return ListTile(
                    title: Text(_formatDate(date)),
                    subtitle: Text('Durasi: $selectedDuration jam'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
