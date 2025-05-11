import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/screens_pelanggan/Kalender.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'price_list.dart';
import 'tentang_kami.dart';

// Event Promo data model
class EventPromo {
  final Image imageUrl;

  EventPromo({required this.imageUrl});
}

// Sample event data
final List<EventPromo> events = [
  EventPromo(imageUrl: Image.asset("assets/image/PromoEvent.jpeg")),
  EventPromo(imageUrl: Image.asset("assets/image/PromoEvent.jpeg")),
  EventPromo(imageUrl: Image.asset("assets/image/PromoEvent.jpeg")),
];

// Court data model
class Court {
  final Image imageUrl;
  final String name;
  final bool isAvailable;
  final double pricePerHour;

  Court({
    required this.imageUrl,
    required this.name,
    this.isAvailable = true,
    this.pricePerHour = 0,
  });
}

// Sample courts data
final List<Court> courts = [
  Court(
    imageUrl: Image.asset("assets/image/Lapangan.jpg"),
    name: "Lapangan 1",
    pricePerHour: 50000,
  ),
  Court(
    imageUrl: Image.asset("assets/image/Lapangan.jpg"),
    name: "Lapangan 3",
    pricePerHour: 45000,
  ),
  Court(
    imageUrl: Image.asset("assets/image/Lapangan.jpg"),
    name: "Lapangan 4",
    pricePerHour: 60000,
  ),
];

// Booking data model
class Booking {
  final String courtName;
  final String date;
  final String timeSlot;
  final String status;

  Booking({
    required this.courtName,
    required this.date,
    required this.timeSlot,
    required this.status,
  });
}

class Reward {
  final double currentHours;
  final double requiredHours = 20;

  Reward({required this.currentHours});
}

final Reward currentReward = Reward(currentHours: 7);

class HalamanUtamaPelanggan extends StatefulWidget {
  const HalamanUtamaPelanggan({super.key});

  @override
  State<HalamanUtamaPelanggan> createState() => _HalamanUtamaPelanggan();
}

class _HalamanUtamaPelanggan extends State<HalamanUtamaPelanggan> {
  Widget? currentBookingCard;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkbooked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current booking card
                if (currentBookingCard != null) currentBookingCard!,

                SizedBox(height: 10),

                // Quick access buttons
                _buildQuickAccessMenu(),

                const SizedBox(height: 16),

                // Reward section
                _buildRewardection(context),

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
    );
  }

  Widget _buildRewardection(BuildContext context) {
    double progress = (currentReward.currentHours / currentReward.requiredHours)
        .clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              double barWidth = constraints.maxWidth;
              double markerPos =
                  (currentReward.requiredHours / 2) /
                  currentReward.requiredHours *
                  barWidth;
              double markerPos2 =
                  (currentReward.requiredHours) /
                  currentReward.requiredHours *
                  barWidth;

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Background bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Foreground progress
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Marker (halfway point)
                  Positioned(
                    left: markerPos - 5,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                    ),
                  ),
                  // marker (end point)
                  Positioned(
                    left: markerPos2 - 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentReward.currentHours.toInt()}h played',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '${(currentReward.requiredHours - currentReward.currentHours).clamp(0, currentReward.requiredHours).toInt()}h to next reward',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Current booking card widget
  Widget _buildCurrentBookingCard(
    String courtName,
    String timeSlot,
    String date,
  ) {
    Color statusColor = Colors.green;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: statusColor, size: 14),
                const SizedBox(width: 8),

                Text(
                  "Your Current Booking",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Lapangan $courtName • $date • $timeSlot",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement reschedule functionality
                  },
                  label: const Text("Reschedule"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement cancel functionality
                  },
                  label: const Text("Cancel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _checkbooked() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';
    DateTime selectedDate = DateTime.now();

    try {
      final timeSlots = await FirebaseService().getTimeSlotByUsername(
        username,
        selectedDate,
      );

      debugPrint('Time slots: $timeSlots');

      if (timeSlots.isNotEmpty) {
        final timeSlot = timeSlots.first;
        String courtName = timeSlot.courtId;
        String startTime = timeSlot.startTime;
        String date = timeSlot.date.toString();

        // Simpan widget ke state
        setState(() {
          currentBookingCard = _buildCurrentBookingCard(
            courtName,
            startTime,
            date,
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

  // Quick access menu buttons
  Widget _buildQuickAccessMenu() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickAccessButton(
              icon: 'priceList',
              label: "Daftar Harga",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HalamanPriceList()),
                  ),
            ),
            _buildQuickAccessButton(
              icon: 'calender',
              label: "Booking",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HalamanKalender()),
                  ),
            ),
            _buildQuickAccessButton(
              icon: 'aboutUs',
              label: "Tentang Kami",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanTentangKami(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual quick access button
  Widget _buildQuickAccessButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final iconMap = {
      'priceList': Icons.attach_money_outlined,
      'calender': Icons.calendar_month_outlined,
      'aboutUs': Icons.info_outline,
    };

    final IconData iconData = iconMap[icon] ?? Icons.help_outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 32, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Promotions Events
  Widget _buildPromotionsEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            "Promotions & Events",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildPromoCard(events[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // Individual promo card
  Widget _buildPromoCard(EventPromo promo) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(height: 350, width: 200, child: promo.imageUrl),
          ),
        ],
      ),
    );
  }

  // Available courts section
  Widget _buildAvailableCourtsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Available Courts",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: courts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCourtCard(courts[index]),
            );
          },
        ),
      ],
    );
  }

  // Individual court card
  Widget _buildCourtCard(Court court) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HalamanKalender()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                court.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  width: 300,
                  height: 160,
                  child: court.imageUrl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
