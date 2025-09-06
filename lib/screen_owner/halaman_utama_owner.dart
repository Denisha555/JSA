import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screen_owner/laporan.dart';
import 'package:flutter_application_1/screen_owner/pesanan.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HalamanUtamaOwner extends StatefulWidget {
  const HalamanUtamaOwner({super.key});

  @override
  State<HalamanUtamaOwner> createState() => _HalamanUtamaOwnerState();
}

class _HalamanUtamaOwnerState extends State<HalamanUtamaOwner> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _handleLogout();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              Row(
                children: [
                  _buildStatCard(
                    'Pelanggan Hari Ini',
                    FutureBuilder<int>(
                      future: FirebaseGetBooking().getTodayCustomers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData) {
                          return const Text('0');
                        } else {
                          final totalCustomers = snapshot.data!;
                          return Text(
                            '$totalCustomers',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                      },
                    ),
                    Icons.people_outline,
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Pendapatan Hari Ini',
                    FutureBuilder<double>(
                      future: FirebaseGetBooking().getTodayIncome(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData) {
                          return const Text('Rp 0');
                        } else {
                          final todayIncome = snapshot.data!;
                          return Text(
                            'Rp ${_formatCurrency(todayIncome)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                      },
                    ),
                    Icons.monetization_on_outlined,
                    Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Quick Actions Section
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 15),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildMenuCard(
                    'Lihat Pesanan',
                    Icons.list_alt_outlined,
                    Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HalamanPesanan(),
                        ),
                      );
                    }
                  ),
                  _buildMenuCard(
                    'Lihat Laporan',
                    Icons.analytics_outlined,
                    Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HalamanLaporan(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Text(
                'Grafik Booking 7 Hari Terakhir',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 15),

              // Chart Section
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FutureBuilder<Map<String, int>>(
                          future: FirebaseGetBooking().getWeeklyBookings(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error loading chart',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bar_chart_rounded,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tidak ada data',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return _buildChart(snapshot.data!);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 35,)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, int> weeklyData) {
    List<BarChartGroupData> barGroups = [];
    List<String> days = weeklyData.keys.toList();

    for (int i = 0; i < days.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: weeklyData[days[i]]!.toDouble(),
              color: primaryColor.withValues(alpha: 0.8),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              weeklyData.values.isEmpty
                  ? 10
                  : weeklyData.values
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble() +
                      2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${days[group.x.toInt()]}\n${rod.toY.round()} booking',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        days[value.toInt()].substring(
                          0,
                          3,
                        ), // Ambil 3 karakter pertama hari
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
          gridData: FlGridData(
            drawHorizontalLine: false,
            drawVerticalLine: false,
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} M';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} rb';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Widget _buildStatCard(
    String title,
    Widget value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 22,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.1),
          spreadRadius: 1,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap, // Gunakan parameter onTap yang diterima
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah kamu yakin ingin logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('username');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }
}
