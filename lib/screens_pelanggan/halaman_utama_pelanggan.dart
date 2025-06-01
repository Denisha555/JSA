import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/screens_pelanggan/Kalender.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/screens_pelanggan/price_list.dart';
import 'package:flutter_application_1/screens_pelanggan/tentang_kami.dart';

class Reward {
  final double currentHours;
  final double requiredHours;

  const Reward({required this.currentHours, this.requiredHours = 20});
}

class HalamanUtamaPelanggan extends StatefulWidget {
  const HalamanUtamaPelanggan({super.key});

  @override
  State<HalamanUtamaPelanggan> createState() => _HalamanUtamaPelangganState();
}

class _HalamanUtamaPelangganState extends State<HalamanUtamaPelanggan> {
  Widget? currentBookingCard;
  bool _isLoading = false;
  List<UserData> user = [];
  List<EventPromo> events = [];
  List<AllCourtsToday> courts = [];

  // Initialize with default values
  Reward currentReward = const Reward(currentHours: 0);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkBooked();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);

    await Future.wait([
      getUserData(), // Load user data first
      _checkBooked(),
      _getPromoData(),
    ]);

    // Lakukan operasi async terlebih dahulu
    final courtsData = await FirebaseService().getAllLapanganToday();

    // Kemudian update state secara sinkron
    if (mounted) {
      setState(() {
        _isLoading = false;
        courts = courtsData;
      });
    }
  }

  Future<void> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('username');
      if (userId != null) {
        final userData = await FirebaseService().getUserData(userId);

        if (mounted) {
          setState(() {
            user = userData;

            // Cek dan isi currentReward
            final hours = (user.isNotEmpty)
                ? user[0].totalHour.toDouble()
                : 0.0;

            currentReward = Reward(currentHours: hours);
          });
        }
      } else {
        debugPrint('Username not found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data pengguna'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getPromoData() async {
    try {
      List<EventPromo> temp = await FirebaseService().getPromo();
      if (mounted) {
        setState(() {
          events = temp;
        });
      }
    } catch (e) {
      debugPrint('Failed to get promo data: $e');
      // Don't throw exception, just log the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([getUserData(), _checkBooked()]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading indicator
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // Current booking card
                  if (currentBookingCard != null) ...[
                    currentBookingCard!,
                    const SizedBox(height: 16),
                  ],

                  // Quick access buttons
                  _buildQuickAccessMenu(),
                  const SizedBox(height: 16),

                  // Reward section
                  _buildRewardSection(context),
                  const SizedBox(height: 24),

                  // Promotions Events
                  _buildPromotionsEvents(),
                  const SizedBox(height: 24),

                  // Available courts section
                  _buildAvailableCourtsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardSection(BuildContext context) {
    final progress = (currentReward.currentHours / currentReward.requiredHours)
        .clamp(0.0, 1.0);

    final isRewardAvailable1 = currentReward.currentHours >= 10;
    final isRewardAvailable2 = currentReward.currentHours >= 20;

    final nextStageHours = ((currentReward.currentHours / 10).floor() + 1) * 10;
    final hoursToNext = (nextStageHours - currentReward.currentHours).clamp(
      0,
      double.infinity,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Reward Progress',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar with markers
          _buildProgressBar(progress, isRewardAvailable1, isRewardAvailable2),
          const SizedBox(height: 16),

          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentReward.currentHours.toInt()}h dimainkan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${hoursToNext.toInt()}h lagi untuk reward',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    double progress,
    bool isRewardAvailable1,
    bool isRewardAvailable2,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const markerSize = 32.0;
        final barWidth = constraints.maxWidth;
        final firstMarkerPos = (barWidth * 0.5) - (markerSize / 2);
        final secondMarkerPos = barWidth - markerSize;

        return SizedBox(
          height: 40,
          child: Stack(
            children: [
              // Background bar
              Positioned(
                left: 0,
                right: 0,
                top: 16,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Progress bar
              Positioned(
                left: 0,
                top: 16,
                child: Container(
                  width: barWidth * progress,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // First reward marker (10 hours)
              Positioned(
                left: firstMarkerPos,
                top: 4,
                child: _buildRewardMarker(
                  isAvailable: isRewardAvailable1,
                  rewardText: '1 jam gratis',
                  hoursRequired: '10 jam',
                ),
              ),

              // Second reward marker (20 hours)
              Positioned(
                left: secondMarkerPos,
                top: 4,
                child: _buildRewardMarker(
                  isAvailable: isRewardAvailable2,
                  rewardText: '2 jam gratis',
                  hoursRequired: '20 jam',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardMarker({
    required bool isAvailable,
    required String rewardText,
    required String hoursRequired,
  }) {
    return GestureDetector(
      onTap: isAvailable
          ? () => _showRewardDialog(rewardText)
          : () => _showRewardRequirementDialog(hoursRequired),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isAvailable ? Colors.amber : Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          isAvailable ? Icons.card_giftcard : Icons.lock,
          color: isAvailable ? Colors.white : Colors.grey[600],
          size: 18,
        ),
      ),
    );
  }

  void _showRewardDialog(String rewardText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Selamat!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kamu mendapatkan $rewardText!'),
            const SizedBox(height: 12),
            const Text(
              'Catatan: Reward ini dapat digunakan pada booking selanjutnya dengan konfirmasi admin.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showRewardRequirementDialog(String hoursRequired) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reward Terkunci'),
        content: Text(
          'Mainkan hingga $hoursRequired untuk membuka reward ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBookingCard(
    String courtName,
    String timeSlot,
    String date,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Jadwal",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_tennis, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lapangan $courtName",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$date • $timeSlot",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkBooked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      final selectedDate = DateTime.now();

      final timeSlots = await FirebaseService().getTimeSlotByUsername(
        username,
        selectedDate,
      );

      if (!mounted) return;

      if (timeSlots.isNotEmpty) {
        final timeSlot = timeSlots.first;
        setState(() {
          currentBookingCard = _buildCurrentBookingCard(
            timeSlot.courtId,
            timeSlot.startTime,
            timeSlot.date.toString(),
          );
        });
      } else {
        setState(() {
          currentBookingCard = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to load booking: $e');
    }
  }

  Widget _buildQuickAccessMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAccessButton(
            icon: Icons.attach_money_outlined,
            label: "Daftar Harga",
            color: Colors.green,
            onTap: () => _navigateToScreen(const HalamanPriceList()),
          ),
          _buildQuickAccessButton(
            icon: Icons.calendar_month_outlined,
            label: "Booking",
            color: primaryColor,
            onTap: () => _navigateToScreen(const HalamanKalender()),
          ),
          _buildQuickAccessButton(
            icon: Icons.info_outline,
            label: "Tentang Kami",
            color: Colors.orange,
            onTap: () => _navigateToScreen(const HalamanTentangKami()),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    // Refresh data when returning from other screens
    await Future.wait([getUserData(), _checkBooked()]);
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Promosi & Event",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        events.isNotEmpty
            ? SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < events.length - 1 ? 16 : 0,
                      ),
                      child: _buildPromoCard(events[index]),
                    );
                  },
                ),
              )
            : const Center(child: Text("Tidak ada promo atau event saat ini")),
      ],
    );
  }

  Widget _buildPromoCard(EventPromo promo) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.memory(
              base64Decode(promo.image),
              height: 200,
              width: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: 160,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCourtsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        courts.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lapangan Tersedia",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                      child: Text("Tidak ada lapangan tersedia saat ini")),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lapangan Tersedia",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => _navigateToScreen(const HalamanKalender()),
                    child: const Text("Lihat Semua"),
                  ),
                ],
              ),
        const SizedBox(height: 12),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: courts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCourtCard(courts[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourtCard(AllCourtsToday court) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToScreen(const HalamanKalender()),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.memory(
                    base64Decode(court.image),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 160,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Tersedia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lapangan ${court.courtId}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Indoor Court',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}