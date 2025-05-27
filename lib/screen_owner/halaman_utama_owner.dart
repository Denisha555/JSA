import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HalamanUtamaOwner extends StatelessWidget {
  const HalamanUtamaOwner({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () async {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MyApp()),
                  );
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  prefs.remove('username');
                },
                child: Icon(Icons.logout),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text(
                "Today's Summary",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryCard("Total Bookings Today", "12"),
                  const SizedBox(width: 12),
                  _summaryCard("Today's Revenue", "\$480"),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Reports",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Today"),
                    Tab(text: "This Week"),
                    Tab(text: "This Month"),
                    Tab(text: "Custom Range"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400, // tinggi area konten tab
                child: TabBarView(
                  children: [
                    _tabContent("12", "\$480"),
                    _tabContent("34", "\$1280"),
                    _tabContent("103", "\$3920"),
                    _tabContent("?", "?"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _summaryCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _tabContent(String bookings, String revenue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Booking Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(bookings, style: const TextStyle(fontSize: 32)),
        const Text("Today"),
        const SizedBox(height: 16),
        Container(
          height: 100,
          color: Colors.grey[300],
          child: const Center(child: Text("Booking Bar Chart Placeholder")),
        ),
        const SizedBox(height: 24),
        const Text(
          "Revenue Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(revenue, style: const TextStyle(fontSize: 32)),
        const Text("Today"),
        const SizedBox(height: 16),
        Container(
          height: 100,
          color: Colors.grey[300],
          child: const Center(child: Text("Revenue Line Chart Placeholder")),
        ),
      ],
    );
  }
}
