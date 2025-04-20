import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HalamanPriceList extends StatefulWidget {
  const HalamanPriceList({super.key});

  @override
  State<HalamanPriceList> createState() => _HalamanPriceListState();
}

class _HalamanPriceListState extends State<HalamanPriceList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _memberPrices = [];
  List<Map<String, dynamic>> _nonMemberPrices = [];

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Harga")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadPrices,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Member section
                      _buildPricingTable(
                        title: "Member",
                        prices: _memberPrices,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 24),

                      // Non-Member section
                      _buildPricingTable(
                        title: "Non Member",
                        prices: _nonMemberPrices,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);

    try {
      // Get prices from Firestore
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('harga').get();

      // Process and organize by membership type
      final List<Map<String, dynamic>> memberPrices = [];
      final List<Map<String, dynamic>> nonMemberPrices = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Create a display-friendly map with all the needed info
        final Map<String, dynamic> priceInfo = {
          'type': data['type'],
          'jam_mulai': data['jam_mulai'],
          'jam_selesai': data['jam_selesai'],
          'hari_mulai': data['hari_mulai'],
          'hari_selesai': data['hari_selesai'],
          'harga': data['harga'],
          'display_time': '${data['jam_mulai']}.00 - ${data['jam_selesai']}.00',
          'display_day': '${data['hari_mulai']} - ${data['hari_selesai']}',
        };

        // Sort by membership type
        if (data['type'] == 'Member') {
          memberPrices.add(priceInfo);
        }
        if (data['type'] == 'Non Member') {
          nonMemberPrices.add(priceInfo);
        }

        // Sorting harga sesuai hari dan waktu
        memberPrices.sort((a, b) {
          int dayA = getDayIndex(a['hari_mulai']);
          int dayB = getDayIndex(b['hari_mulai']);
          if (dayA != dayB) return dayA.compareTo(dayB);

          // Kalau harinya sama, baru bandingkan jam
          int timeA = a['jam_mulai'];
          int timeB = b['jam_mulai'];
          return timeA.compareTo(timeB);
        });

        nonMemberPrices.sort((a, b) {
          int dayA = getDayIndex(a['hari_mulai']);
          int dayB = getDayIndex(b['hari_mulai']);
          if (dayA != dayB) return dayA.compareTo(dayB);

          int timeA = a['jam_mulai'];
          int timeB = b['jam_mulai'];
          return timeA.compareTo(timeB);
        });
      }
      setState(() {
        _memberPrices = memberPrices;
        _nonMemberPrices = nonMemberPrices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load prices: $e')));
      }
    }
  }

  int getDayIndex(String day) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return days.indexOf(day);
  }

  Widget _buildPricingTable({
    required String title,
    required List<Map<String, dynamic>> prices,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Group by day type (weekday vs weekend)
            ..._buildDayGroupedPrices(prices, color),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDayGroupedPrices(
    List<Map<String, dynamic>> prices,
    Color color,
  ) {
    // Group prices by day type
    final Map<String, List<Map<String, dynamic>>> groupedPrices = {};

    for (var price in prices) {
      final String dayKey = '${price['hari_mulai']} - ${price['hari_selesai']}';

      if (!groupedPrices.containsKey(dayKey)) {
        groupedPrices[dayKey] = [];
      }

      groupedPrices[dayKey]!.add(price);
    }

    // Build widgets for each day group
    final List<Widget> widgets = [];

    groupedPrices.forEach((dayRange, dayPrices) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radio_button_checked_outlined),
                const SizedBox(width: 8),
                Text(
                  dayRange,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Build each time slot row
            ...dayPrices
                .map(
                  (price) => _buildPriceRow(
                    timeRange: price['display_time'],
                    price: price['harga'],
                    color: color.withValues(alpha: 0.1),
                  ),
                )
                .toList(),

            const SizedBox(height: 20),
          ],
        ),
      );
    });

    return widgets;
  }

  Widget _buildPriceRow({
    required String timeRange,
    required int price,
    required Color color,
  }) {
    // Format price with IDR currency
    final String formattedPrice = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              timeRange,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            formattedPrice,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
