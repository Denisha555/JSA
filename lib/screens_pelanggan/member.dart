import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HalamanMember extends StatefulWidget {
  const HalamanMember({super.key});

  @override
  State<HalamanMember> createState() => _HalamanMemberState();
}

List<DateTime> getAllWeekdaysInMonth(int weekday, DateTime baseDate) {
  final firstDay = DateTime(baseDate.year, baseDate.month, 1);
  final lastDay = DateTime(baseDate.year, baseDate.month + 1, 0);

  return List.generate(lastDay.day, (i) => firstDay.add(Duration(days: i)))
      .where((d) => d.weekday == weekday)
      .toList();
}

class _HalamanMemberState extends State<HalamanMember> {
  String selectedDuration = '2';
  int? selectedWeekday; // Nilai weekday: 1=Mon ... 7=Sun
  List<DateTime> selectedDates = [];

  final Map<String, int> weekdayMap = {
    'Mon': 1,
    'Tue': 2,
    'Wed': 3,
    'Thu': 4,
    'Fri': 5,
    'Sat': 6,
    'Sun': 7,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Berkala Member')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Hari'),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: weekdayMap.keys.map((day) {
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
                          selectedDates = getAllWeekdaysInMonth(
                              selectedWeekday!, currentMonth);
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
                    title: Text(DateFormat('EEEE, dd MMMM yyyy').format(date)),
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
