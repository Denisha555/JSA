import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/model/user_model.dart';
import 'package:flutter_application_1/model/court_model.dart';
import 'package:flutter_application_1/model/reward_model.dart';
import 'package:flutter_application_1/function/reward/reward.dart';
import 'package:flutter_application_1/model/event_promo_model.dart';
import 'package:flutter_application_1/screens_pelanggan/price.dart';
import 'package:flutter_application_1/screens_pelanggan/Kalender.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/screens_pelanggan/tentang_kami.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:flutter_application_1/services/court/firebase_get_court.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';
import 'package:flutter_application_1/services/event_promo/firebase_get_event_promo.dart';

class HalamanUtamaPelanggan extends StatefulWidget {
  const HalamanUtamaPelanggan({super.key});

  @override
  State<HalamanUtamaPelanggan> createState() => _HalamanUtamaPelangganState();
}

class _HalamanUtamaPelangganState extends State<HalamanUtamaPelanggan> {
  Widget? currentBookingCard;
  bool _isLoading = false;
  List<UserModel> user = [];
  List<EventPromoModel> events = [];
  List<CourtModel> courts = [];

  // Initialize with default values
  RewardModel currentReward = RewardModel(currentHours: 0);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);

    await getUserData();

    await Future.wait([_checkBooked(), _getPromoData()]);

    // Lakukan operasi async terlebih dahulu
    final courtsData = await FirebaseGetCourt().getAllLapanganToday();

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
        await Future.wait([
          FirebaseCheckUser().checkMembership(userId),
          FirebaseCheckUser().checkRewardTime(userId),
        ]);
        final userData = await FirebaseGetUser().getUserByUsername(userId);

        if (mounted) {
          setState(() {
            user = userData;

            final hours = (user.isNotEmpty) ? user[0].point.toDouble() : 0.0;

            currentReward = RewardModel(currentHours: hours);

            bool isMember = user.isNotEmpty ? user[0].role == 'member' : false;

            if (isMember) {
              prefs.setBool('isMember', true);

              int memberTotalBooking = user[0].memberTotalBooking;
              int memberCurrentTotalBooking = user[0].memberCurrentTotalBooking;
              int memberBookingLength = user[0].memberBookingLength;

              prefs.setInt('memberTotalBooking', memberTotalBooking);
              prefs.setInt(
                'memberCurrentTotalBooking',
                memberCurrentTotalBooking,
              );
              prefs.setInt('memberBookingLength', memberBookingLength);
              
            } else {
              prefs.setBool('isMember', false);
            }
          });
        }
      } else {
        debugPrint('Username not found in SharedPreferences');
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal memuat data pengguna');
    }
  }

  Future<void> _getPromoData() async {
    try {
      final temp = await FirebaseGetEventPromo().getPromo();
      if (mounted) {
        setState(() {
          events = temp;
        });
      }
    } catch (e) {
      debugPrint('Failed to get promo data: $e');
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
                  Reward(currentReward: currentReward),
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

      final timeSlots = await FirebaseGetBooking().getBookingByUsername(
        username,
        selectedDate: selectedDate,
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
            color: Colors.grey.withValues(alpha: 0.1),
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
                color: color.withValues(alpha: 0.1),
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

  Widget _buildPromoCard(EventPromoModel promo) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder:
                (context) => Dialog(
                  backgroundColor: Colors.black.withValues(alpha: 0.8),
                  insetPadding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      // Gambar besar
                      InteractiveViewer(
                        child: Image.memory(
                          base64Decode(promo.image),
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Tombol close di pojok kanan atas
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          );
        },
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
                  child: Text("Tidak ada lapangan tersedia saat ini"),
                ),
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

  Widget _buildCourtCard(CourtModel court) {
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
                    base64Decode(court.imageUrl!),
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
