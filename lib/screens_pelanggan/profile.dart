
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/model/user_model.dart';
import 'package:flutter_application_1/model/reward_model.dart';
import 'package:flutter_application_1/function/price/price.dart';
import 'package:flutter_application_1/model/time_slot_model.dart';
import 'package:flutter_application_1/function/reward/reward.dart';
import 'package:flutter_application_1/screens_pelanggan/member.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/screens_pelanggan/edit_profil.dart';
import 'package:flutter_application_1/function/profil/edit_password.dart';
import 'package:flutter_application_1/function/profil/edit_username.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';
import 'package:flutter_application_1/services/booking/firebase_get_booking.dart';
import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';

class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  String? username;
  int memberTotalBooking = 0;
  bool isLoading = true;
  bool? isMemberDatabase;
  bool? isMemberUI;
  List<TimeSlotModel> activity = [];
  List<UserModel> data = [];
  List<TimeSlotModel> userbooked = [];
  RewardModel currentReward = RewardModel(currentHours: 0);
  int? endTime;

  @override
  void initState() {
    super.initState();
    _init();
    loadPrefs();
  }


  Future<void> _init() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _loadData();
      if (username != null && username!.isNotEmpty) {
        await FirebaseCheckUser().checkRewardTime(username!);
        final type = await FirebaseCheckUser().checkUserType(username!);
        final result = type == 'member' ? true : false;

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // simpan status asli dari database (boleh atau tidak tergantung kebutuhan)
        await prefs.setBool('isMember', result);

        // hanya simpan isMemberUI jika member
        if (result == true) {
          // kalau member, ambil preferensi user
          bool? userPreference = prefs.getBool('isMemberUI');
          int memberTotalBooking = await FirebaseGetUser().getUserData(username!, 'memberTotalBooking');

          setState(() {
            isMemberDatabase = true;
            memberTotalBooking = memberTotalBooking;
            isMemberUI =
                userPreference ??
                true; // default ke true kalau belum pernah di-set
            prefs.setBool('isMemberUI', true);
          });
        } else {
          // kalau bukan member, tidak boleh ada UI member
          await prefs.setBool('isMemberUI', false);

          setState(() {
            isMemberDatabase = false;
            isMemberUI = false;
          });
        }
        if (isMemberDatabase! &&
            data.isNotEmpty &&
            data[0].startTimeMember.isNotEmpty) {
          try {
            final startDate = DateTime.parse(data[0].startTimeMember);

            final finishDate = DateTime(
              startDate.year,
              startDate.month + 1,
              startDate.day,
            );

            final now = DateTime.now();
            final difference = finishDate.difference(now);
            final daysLeft = difference.inDays;

            if (daysLeft <= 0) {
              setState(() {
                endTime = 0;
                userbooked = [];
              });
              await FirebaseUpdateUser().updateUser(
                'role',
                username!,
                'nonMember',
              );
              await FirebaseUpdateUser().updateUser(
                'startTimeMember',
                username!,
                '',
              );

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isMember', false);
              await prefs.setBool('isMemberUI', false);

              setState(() {
                isMemberDatabase = false;
                isMemberUI = false;
              });
            } else {
              setState(() {
                endTime = daysLeft;
              });
              await _loadMemberBookings();
            }
          } catch (e) {
            setState(() {
              endTime = null;
              userbooked = [];
            });
          }
        } else {
          setState(() {
            endTime = null;
            userbooked = [];
          });
        }

        await getLastActivity();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Failed to load profil data');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? savedDB = prefs.getBool('isMember');
    bool? savedUI = prefs.getBool('isMemberUI');

    if (savedDB != null) {
      setState(() {
        isMemberDatabase = savedDB;
        isMemberUI = savedDB ? (savedUI ?? true) : false;
      });
    }
  }

  Future<void> _loadMemberBookings() async {
    try {
      if (username == null) return;

      final temp = await FirebaseGetBooking().getBookingByUsername(username!);

      List<TimeSlotModel> memberBookings = [];

      for (var booking in temp) {
        try {
          // Cek apakah booking masih berlaku dan merupakan booking member
          if (booking.type == 'member' && booking.status != 'finish') {
            memberBookings.add(booking);
          }
        } catch (e) {
          if (!mounted) return;
          showErrorSnackBar(context, 'Failed to load booking data');
        }
      }

      // Sort bookings by date and time (ascending)
      memberBookings.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.date.toString());
          final dateB = DateTime.parse(b.date.toString());

          int dateComparison = dateA.compareTo(dateB);
          if (dateComparison != 0) {
            return dateComparison;
          }

          // Jika tanggal sama, sort berdasarkan startTime
          return a.startTime.toString().compareTo(b.startTime.toString());
        } catch (e) {
          showErrorSnackBar(context, 'Failed to load booking data');
          return 0;
        }
      });

      // Group bookings by date dan combine jam
      List<TimeSlotModel> consolidatedBookings = [];
      Map<String, List<TimeSlotModel>> groupedByDate = {};

      // Group booking berdasarkan tanggal
      for (var booking in memberBookings) {
        try {
          final dateKey =
              '${DateTime.parse(
                booking.date.toString(),
              ).toIso8601String().split('T')[0]}_${booking.courtId}';

          if (!groupedByDate.containsKey(dateKey)) {
            groupedByDate[dateKey] = [];
          }
          groupedByDate[dateKey]!.add(booking);
        } catch (e) {
          debugPrint('Error grouping bookings: $e');
        }
      }

      // Combine bookings untuk setiap tanggal
      for (var dateEntry in groupedByDate.entries) {
        List<TimeSlotModel> dayBookings = dateEntry.value;

        if (dayBookings.isNotEmpty) {
          // Sort berdasarkan startTime untuk hari ini
          dayBookings.sort(
            (a, b) => a.startTime.toString().compareTo(b.startTime.toString()),
          );

          // Ambil booking pertama sebagai base
          TimeSlotModel consolidatedBooking = dayBookings.first;

          // Update endTime dengan endTime dari booking terakhir di hari yang sama
          if (dayBookings.length > 1) {
            consolidatedBooking = TimeSlotModel(
              // Copy semua properti dari booking pertama
              username: consolidatedBooking.username,
              courtId: consolidatedBooking.courtId,
              date: consolidatedBooking.date,
              startTime:
                  consolidatedBooking.startTime, // Jam mulai dari yang pertama
              endTime:
                  dayBookings.last.endTime, // Jam selesai dari yang terakhir
              type: consolidatedBooking.type,
              // Tambahkan properti lain sesuai dengan struktur AllBookedUser Anda
            );
          }

          consolidatedBookings.add(consolidatedBooking);
        }
      }

      // Sort consolidated bookings by date
      consolidatedBookings.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.date.toString());
          final dateB = DateTime.parse(b.date.toString());
          return dateA.compareTo(dateB);
        } catch (e) {
          debugPrint('Error sorting consolidated bookings: $e');
          return 0;
        }
      });

      setState(() {
        userbooked = consolidatedBookings;
      });
    } catch (e) {
      debugPrint('Error loading member bookings: $e');
      setState(() {
        userbooked = [];
      });
    }
  }

  Future<void> _loadData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? loadedUsername = prefs.getString('username');

      if (loadedUsername == null || loadedUsername.isEmpty) {
        return;
      }

      List<UserModel> temp = await FirebaseGetUser().getUserByUsername(
        loadedUsername,
      );

      if (!mounted) return;

      setState(() {
        username = loadedUsername;
        data = temp;

        // Update currentReward with actual user data
        final hours = (data.isNotEmpty) ? data[0].point.toDouble() : 0.0;
        currentReward = RewardModel(currentHours: hours);
      });
    } catch (e) {
      throw Exception('Error loading user data : $e');
    }
  }

  Future<void> getLastActivity() async {
    try {
      if (username != null) {
        final temp = await FirebaseGetBooking().getBookingByUsername(username!);
        if (temp.isNotEmpty && mounted) {
          setState(() {
            activity = temp;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting last activity: $e');
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [SizedBox(width: 8), Text('Konfirmasi Keluar')],
            ),
            content: const Text('Apakah kamu yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('username');
        await prefs.remove('isMember');
        await prefs.remove('isMemberUI');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      } catch (e) {
        if (!mounted) return;
        showErrorSnackBar(context, 'Error logging out: $e');
      }
    }
  }

  Widget _buildStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.grey[100],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              '${data.isNotEmpty ? data[0].totalBooking.toString() : 0}',
              'Booking',
            ),
            Container(height: 40, width: 1, color: Colors.grey[300]),
            _buildStatItem(
              '${data.isNotEmpty ? data[0].totalHour.toStringAsFixed(1) : 0}',
              'Point',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _memberSchedule() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.schedule, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Jadwal Member",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content berdasarkan kondisi
              if (userbooked.isEmpty) ...[
                // Jika tidak ada booking
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "Belum ada jadwal booking",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Silakan lakukan booking terlebih dahulu",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                FutureBuilder<double>(
                  future: totalPrice(
                    startTime: userbooked[0].startTime,
                    endTime: userbooked[0].endTime,
                    selectedDate: DateTime.parse(userbooked[0].date),
                    type: 'member',
                  ),

                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Menghitung harga...',
                        style: TextStyle(fontSize: 16),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        'Gagal menghitung harga: ${snapshot.error}',
                        style: TextStyle(fontSize: 16),
                      );
                    } else {
                      
                      final price = snapshot.data ?? 0;
                      final total = price * userbooked.length;

                      return Text(
                        'Total Harga: Rp ${price == 0 ? '0.00' : total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                // Jika ada booking - tampilkan semua jadwal yang sudah dikonsolidasi
                Text(
                  "Jadwal Booking Anda:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                ...userbooked
                    .map(
                      (booking) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tanggal
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(booking.date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Info lapangan
                            _buildScheduleItem(
                              icon: Icons.sports_tennis,
                              label: "Lapangan",
                              value: booking.courtId.toString(),
                            ),
                            const SizedBox(height: 4),

                            // Waktu (sudah dikonsolidasi)
                            _buildScheduleItem(
                              icon: Icons.access_time,
                              label: "Waktu",
                              value:
                                  "${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}",
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],

              const SizedBox(height: 20),

              // Tombol aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Tutup"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return "Tidak tersedia";

    try {
      if (time is String) {
        // Jika sudah dalam format string yang readable
        if (time.contains(':')) {
          return time;
        }
        // Jika dalam format DateTime string
        final dateTime = DateTime.parse(time);
        return DateFormat('HH:mm').format(dateTime);
      } else if (time is DateTime) {
        return DateFormat('HH:mm').format(time);
      }
      return time.toString();
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return time.toString();
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return "Tidak tersedia";

    try {
      if (date is String) {
        final dateTime = DateTime.parse(date);
        return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dateTime);
      } else if (date is DateTime) {
        return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
      }
      return date.toString();
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat profil...'),
            ],
          ),
        ),
      );
    }

    // If username is null, redirect to login
    if (username == null || username!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainApp()),
        );
      });
      return const Scaffold(
        body: Center(child: Text('Redirecting to login...')),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _init,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Profile header with avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 200,
                    padding: const EdgeInsets.only(
                      top: 20,
                      right: 20,
                      left: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'profile_avatar',
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor:
                                isMemberUI!
                                    ? Colors.blueAccent
                                    : Colors.grey[400]!,
                            child: Text(
                              username![0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                username!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${data.isNotEmpty ? data[0].totalHour.toStringAsFixed(1) : 0} Poin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isMemberUI!)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '💎 Member',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        isMemberDatabase == true
                            ? Switch(
                              value: isMemberUI!,
                              onChanged: (value) async {
                                setState(() {
                                  isMemberUI = value;
                                });
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('isMember', value);
                                await prefs.setBool('isMemberUI', value);
                              },
                              activeColor: Colors.white,
                            )
                            : Text(''),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: -45,
                    left: 20,
                    right: 20,
                    child: _buildStatsCard(),
                  ),
                ],
              ),

              const SizedBox(height: 55),

              isMemberDatabase == true
                  ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Text(
                          isMemberUI! ? '💎' : '🪨',
                          style: const TextStyle(fontSize: 30),
                        ),
                        title: Text(
                          isMemberUI! ? 'Member' : 'Non Member',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle:
                            isMemberUI!
                                ? Text(
                                  // 'Berakhir dalam ${endTime.toString()} hari',
                                  'Tap untuk lihat jadwal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                )
                                : const Text(
                                  'Anda sekarang sedang menggunakan mode Non Member',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                        onTap:
                            isMemberUI!
                                ? () {
                                  // Navigate to member schedule or details
                                  showDialog(
                                    context: context,
                                    builder: (context) => _memberSchedule(),
                                  ).then((_) => _init());
                                }
                                : null,
                      ),
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Text(
                          '🪨',
                          style: const TextStyle(fontSize: 30),
                        ),
                        title: Text(
                          'Non Member',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Upgrade untuk mendapatkan benefit lebih',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HalamanMember(),
                            ),
                          ).then((_) => _init());
                        },
                      ),
                    ),
                  ),

              const SizedBox(height: 20),

              // Activity history section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktivitas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          activity.isEmpty
                              ? 'Belum Ada Aktivitas'
                              : 'Booked Court - Lapangan ${activity[0].courtId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle:
                            activity.isEmpty
                                ? const Text('Mulai booking lapangan sekarang!')
                                : Text(activity[0].date),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PilihHalamanPelanggan(selectedIndex: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reward progress section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progres Reward',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Reward(currentReward: currentReward),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile management section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengaturan Profil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.edit,
                              size: 20,
                              color: primaryColor,
                            ),
                            title: const Text('Edit Profil'),
                            subtitle: const Text('Ubah data diri Anda'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HalamanEditProfil(),
                                ),
                              );
                            },
                          ),

                          const Divider(height: 1),

                          ListTile(
                            leading: Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: primaryColor,
                            ),
                            title: const Text('Ubah Username'),
                            subtitle: const Text('Ubah username Anda'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => EditUsername(),
                              );
                            },
                          ),

                          const Divider(height: 1),

                          ListTile(
                            leading: Icon(
                              Icons.lock,
                              size: 20,
                              color: primaryColor,
                            ),
                            title: const Text('Ubah Password'),
                            subtitle: const Text('Perbarui kata sandi Anda'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => EditPassword(),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.logout_sharp,
                              size: 20,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Keluar',
                              style: TextStyle(color: Colors.red),
                            ),
                            subtitle: const Text('Keluar dari akun Anda'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.red,
                            ),
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
