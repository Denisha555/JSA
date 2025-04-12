// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/screens_pelanggan/Kalender.dart';
// import 'price_list.dart';
// import 'tentang_kami.dart';

// class EventPromo {
//   final String imageUrl;

//   EventPromo({required this.imageUrl});
// }

// List<EventPromo> events = [
//   EventPromo(imageUrl: "https://via.placeholder.com/150"),
//   EventPromo(imageUrl: "https://via.placeholder.com/150"),
//   EventPromo(imageUrl: "https://via.placeholder.com/150"),
// ];

// class Courts {
//   final String imageUrl;
//   final String name;

//   Courts({required this.imageUrl, required this.name});
// }

// List<Courts> courts = [
//   Courts(imageUrl: "https://via.placeholder.com/150", name: "Court 1"),
//   Courts(imageUrl: "https://via.placeholder.com/150", name: "Court 2"),
//   Courts(imageUrl: "https://via.placeholder.com/150", name: "Court 3"),
// ];

// class HalamanUtamaPelanggan extends StatefulWidget {
//   const HalamanUtamaPelanggan({super.key});

//   @override
//   State<HalamanUtamaPelanggan> createState() => _HalamanUtama();
// }

// class _HalamanUtama extends State<HalamanUtamaPelanggan> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Dashboard")),
//       body: SingleChildScrollView(
//         scrollDirection: Axis.vertical,
//         child: Padding(
//           padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(top: 10, bottom: 10),
//                 child: Container(
//                   height: 150,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.shade400,
//                         blurRadius: 1.2,
//                         offset: Offset(0, 0.5),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(20.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.circle, color: Colors.green, size: 15),
//                             SizedBox(width: 10),
//                             Text(
//                               "Terkonfirmasi",
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Text(
//                           "Lapangan 2 • 10:00 - 12:00 • 20/02/2023",
//                           style: TextStyle(fontSize: 15),
//                         ),
//                         SizedBox(height: 10),
//                         ElevatedButton(
//                           onPressed: () {},
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                           ),
//                           child: Text(
//                             "Batalkan",
//                             style: TextStyle(fontSize: 15, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 10),
//                 child: SizedBox(
//                   height: 75,
//                   child: Padding(
//                     padding: EdgeInsets.all(3),
//                     child: Row(
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.only(right: 10),
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => HalamanPriceList(),
//                                 ),
//                               );
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.white,
//                               minimumSize: Size(45, 70),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             child: Column(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 10),
//                                   child: Image.asset(
//                                     "assets/image/PriceList.jpeg",
//                                     width: 30,
//                                     height: 30,
//                                   ),
//                                 ),
//                                 Text(
//                                   "Price List",
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                     fontSize: 10,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.only(right: 10),
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => HalamanKalender(),
//                                 ),
//                               );
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.white,
//                               minimumSize: Size(45, 70),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             child: Column(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 10),
//                                   child: Image.asset(
//                                     "assets/image/Kalender.jpeg",
//                                     width: 30,
//                                     height: 30,
//                                   ),
//                                 ),
//                                 Text(
//                                   "Kalender",
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                     fontSize: 10,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         ElevatedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder:
//                                     (context) => const HalamanTentangKami(),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             minimumSize: Size(45, 70),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: Column(
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 10),
//                                 child: Image.asset(
//                                   "assets/image/TentangKami.png",
//                                   width: 30,
//                                   height: 30,
//                                 ),
//                               ),
//                               Text(
//                                 "Tentang Kami",
//                                 style: TextStyle(
//                                   color: Colors.black,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Container(
//                   height: 230,
//                   decoration: BoxDecoration(
//                     color: Color.fromRGBO(133, 170, 211, 1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Container(
//                           width: 140,
//                           height: 185,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SingleChildScrollView(
//                 scrollDirection: Axis.vertical,
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 15, bottom: 20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Availble Courts",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 10),
//                         child: SizedBox(
//                           width: double.infinity,
//                           height: 200,
//                           child: ElevatedButton(
//                             onPressed: () {},
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             child: Text("Lapangan 1"),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens_pelanggan/Kalender.dart';
import 'price_list.dart';
import 'tentang_kami.dart';

// Event Promo data model
class EventPromo {
  final String imageUrl;
  final String title;
  final String description;

  EventPromo({required this.imageUrl, this.title = '', this.description = ''});
}

// Sample event data
final List<EventPromo> events = [
  EventPromo(
    imageUrl: "https://via.placeholder.com/150",
    title: "Weekend Special",
    description: "20% off all bookings this weekend!",
  ),
  EventPromo(
    imageUrl: "https://via.placeholder.com/150",
    title: "New Court Opening",
    description: "Try our new premium court",
  ),
  EventPromo(
    imageUrl: "https://via.placeholder.com/150",
    title: "Member Discount",
    description: "Special rates for members",
  ),
];

// Court data model
class Court {
  final String imageUrl;
  final String name;
  final String description;
  final bool isAvailable;
  final double pricePerHour;

  Court({
    required this.imageUrl,
    required this.name,
    this.description = '',
    this.isAvailable = true,
    this.pricePerHour = 0,
  });
}

// Sample courts data
final List<Court> courts = [
  Court(
    imageUrl: "https://via.placeholder.com/150",
    name: "Court 1",
    description: "Indoor court with professional flooring",
    pricePerHour: 50000,
  ),
  Court(
    imageUrl: "https://via.placeholder.com/150",
    name: "Court 2",
    description: "Outdoor court with lights",
    pricePerHour: 45000,
  ),
  Court(
    imageUrl: "https://via.placeholder.com/150",
    name: "Court 3",
    description: "Premium court with seating area",
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

// Sample current booking
final Booking currentBooking = Booking(
  courtName: "Lapangan 2",
  date: "20/02/2023",
  timeSlot: "10:00 - 12:00",
  status: "Terkonfirmasi",
);

class HalamanUtamaPelanggan extends StatefulWidget {
  const HalamanUtamaPelanggan({super.key});

  @override
  State<HalamanUtamaPelanggan> createState() => _HalamanUtama();
}

class _HalamanUtama extends State<HalamanUtamaPelanggan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current booking card
                if (currentBooking != null) _buildCurrentBookingCard(),

                const SizedBox(height: 16),

                // Quick access buttons
                _buildQuickAccessMenu(),

                const SizedBox(height: 24),

                // Promotions carousel
                _buildPromotionsCarousel(),

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

  // Current booking card widget
  Widget _buildCurrentBookingCard() {
    Color statusColor = Colors.green;

    if (currentBooking.status == "Menunggu Konfirmasi") {
      statusColor = Colors.orange;
    } else if (currentBooking.status == "Dibatalkan") {
      statusColor = Colors.red;
    }

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
                  currentBooking.status,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${currentBooking.courtName} • ${currentBooking.timeSlot} • ${currentBooking.date}",
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
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text("Reschedule"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement cancel functionality
                  },
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text("Batalkan"),
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

  // Quick access menu buttons
  Widget _buildQuickAccessMenu() {
    return Container(
      height: 100,
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
              label: "Price List",
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HalamanPriceList()),
                  ),
            ),
            _buildQuickAccessButton(
              icon: 'calender',
              label: "Kalender",
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
                      builder: (context) => const HalamanTentangKami(),
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

  // Promotions carousel
  Widget _buildPromotionsCarousel() {
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
          height: 180,
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
      width: 280,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(133, 170, 211, 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              promo.imageUrl,
              width: 280,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: 280,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  promo.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to court detail/booking page
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  court.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      court.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Rp ${court.pricePerHour.toStringAsFixed(0)}/jam",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implement booking functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text(
                            "Book Now",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
