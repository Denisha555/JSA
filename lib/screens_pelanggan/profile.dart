import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens_pelanggan/edit_profil.dart';
import 'package:flutter_application_1/screens_pelanggan/member.dart';
import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/screens_pelanggan/halaman_utama_pelanggan.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class HalamanProfil extends StatefulWidget {
  const HalamanProfil({super.key});

  @override
  State<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends State<HalamanProfil> {
  String? username;
  bool isLoading = true;
  bool isMember = false;
  List<LastActivity> activity = [];
  List<UserData> data = [];
  List<AllBookedUser> userbooked = [];
  Reward currentReward = const Reward(currentHours: 0);
  int? endTime;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _loadData();
      if (username != null && username!.isNotEmpty) {
        // Cek member status terlebih dahulu
        final result = await FirebaseService().memberOrNonmember(username!);

        setState(() {
          isMember = result;
        });

        // Setelah isMember diset, baru hitung endTime jika user adalah member
        if (isMember && data.isNotEmpty && data[0].startTimeMember.isNotEmpty) {
          try {
            // Parse startTime dengan penanganan error
            final startDate = DateTime.parse(data[0].startTimeMember);

            // Tambahkan 1 bulan ke startTime
            final finishDate = DateTime(
              startDate.year,
              startDate.month + 1,
              startDate.day,
            );

            // Hitung selisih hari dari sekarang
            final now = DateTime.now();
            final difference = finishDate.difference(now);
            final daysLeft = difference.inDays;

            debugPrint(
              'Start Date: $startDate, Finish Date: $finishDate, Days Left: $daysLeft',
            );

            if (daysLeft <= 0) {
              // Jika membership sudah expired
              setState(() {
                endTime = 0;
                userbooked = []; // Clear booking data
              });
              debugPrint('Membership expired. Days left: $daysLeft');
              await FirebaseService().memberToNonMember(username!);
            } else {
              // Jika masih ada waktu tersisa
              setState(() {
                endTime = daysLeft;
              });
              debugPrint('Membership active. Days left: $daysLeft');

              // Load member bookings
              await _loadMemberBookings();
            }
          } catch (e) {
            debugPrint('Error calculating endTime: $e');
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
      debugPrint('Error initializing profil: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load profil data');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMemberBookings() async {
  try {
    if (username == null) return;

    final now = DateTime.now();
    final temp = await FirebaseService().getAllBookingsByUsername(username!);

    List<AllBookedUser> memberBookings = [];

    for (var booking in temp) {
      // Cek apakah booking masih aktif (belum berakhir)
      if (booking.endTime != null) {
        try {
          final start = DateTime.parse(booking.date.toString());
          
          // Cek apakah booking masih berlaku dan merupakan booking member
          if (start.isAfter(now) && booking.type == 'member') {
            memberBookings.add(booking);
            debugPrint(
              'Found member booking: ${booking.courtId} at ${booking.startTime}',
            );
          }
        } catch (e) {
          debugPrint('Error parsing booking end time: $e');
        }
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
        debugPrint('Error sorting bookings: $e');
        return 0;
      }
    });

    // Group bookings by date dan combine jam
    List<AllBookedUser> consolidatedBookings = [];
    Map<String, List<AllBookedUser>> groupedByDate = {};
    
    // Group booking berdasarkan tanggal
    for (var booking in memberBookings) {
      try {
        final dateKey = DateTime.parse(booking.date.toString()).toIso8601String().split('T')[0];
        
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
      List<AllBookedUser> dayBookings = dateEntry.value;
      
      if (dayBookings.isNotEmpty) {
        // Sort berdasarkan startTime untuk hari ini
        dayBookings.sort((a, b) => a.startTime.toString().compareTo(b.startTime.toString()));
        
        // Ambil booking pertama sebagai base
        AllBookedUser consolidatedBooking = dayBookings.first;
        
        // Update endTime dengan endTime dari booking terakhir di hari yang sama
        if (dayBookings.length > 1) {
          consolidatedBooking = AllBookedUser(
            // Copy semua properti dari booking pertama
            username: consolidatedBooking.username,
            courtId: consolidatedBooking.courtId,
            date: consolidatedBooking.date,
            startTime: consolidatedBooking.startTime, // Jam mulai dari yang pertama
            endTime: dayBookings.last.endTime, // Jam selesai dari yang terakhir
            type: consolidatedBooking.type,
            // Tambahkan properti lain sesuai dengan struktur AllBookedUser Anda
          );
        }
        
        consolidatedBookings.add(consolidatedBooking);
        
        debugPrint(
          'Consolidated booking for ${dateEntry.key}: Court ${consolidatedBooking.courtId}, '
          'Start: ${consolidatedBooking.startTime}, End: ${consolidatedBooking.endTime}'
        );
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

    debugPrint('Loaded ${consolidatedBookings.length} consolidated member bookings');
  } catch (e) {
    debugPrint('Error loading member bookings: $e');
    setState(() {
      userbooked = [];
    });
  }
}

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString(); // ini hasil hash-nya
  }

  Future<void> _loadData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? loadedUsername = prefs.getString('username');

      if (loadedUsername == null || loadedUsername.isEmpty) {
        debugPrint('Username belum tersedia');
        return;
      }

      List<UserData> temp = await FirebaseService().getUserData(loadedUsername);

      if (!mounted) return;

      setState(() {
        username = loadedUsername;
        data = temp;

        // Update currentReward with actual user data
        final hours = (data.isNotEmpty) ? data[0].totalHour.toDouble() : 0.0;
        currentReward = Reward(currentHours: hours);
      });
    } catch (e) {
      debugPrint('Error in _loadData: $e');
      throw Exception('Error loading user data : $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Progress bar with animation
              Positioned(
                left: 0,
                top: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
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
      onTap:
          isAvailable
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
          boxShadow:
              isAvailable
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
      builder:
          (context) => AlertDialog(
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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text('Reward Terkunci'),
              ],
            ),
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

  Future<void> _updatePassword(String newPassword) async {
    if (newPassword.trim().isEmpty) {
      _showErrorSnackBar('Password tidak boleh kosong');
      return;
    }

    if (newPassword.trim().length < 6) {
      _showErrorSnackBar('Password minimal 6 karakter');
      return;
    }

    try {
      if (username != null) {
        await FirebaseService().editPassword(username!, newPassword.trim());
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('password', newPassword.trim());

        if (!mounted) return;
        _showSuccessSnackBar('Password berhasil diperbarui!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Error updating password: $e');
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    if (newUsername.trim().isEmpty) {
      _showErrorSnackBar('Username tidak boleh kosong');
      return;
    }

    try {
      if (username != null) {
        await FirebaseService().editUsername(username!, newUsername.trim());
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', newUsername.trim());
        if (!mounted) return;
        _showSuccessSnackBar('Username berhasil diperbarui!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Error updating username: $e');
    }
  }

  Widget editPassword(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController passwordController2 = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool obscureText = true;
    bool obscureText2 = true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ubah Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Password baru
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.trim().length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Konfirmasi password
                  TextFormField(
                    controller: passwordController2,
                    obscureText: obscureText2,
                    decoration: InputDecoration(
                      hintText: 'Konfirmasi password baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText2
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText2 = !obscureText2;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Konfirmasi password tidak boleh kosong';
                      }
                      if (value != passwordController.text) {
                        return 'Password tidak sama';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Tombol aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            _updatePassword(passwordController.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 45),
                        ),
                        child: const Text('Perbarui'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget editUsername(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ubah Username',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Password baru
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Username Baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Tombol aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            bool usernameUsed = await FirebaseService()
                                .checkUser(usernameController.text);
                            if (!usernameUsed) {
                              _updateUsername(usernameController.text);
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              prefs.setString(
                                'username',
                                usernameController.text,
                              );
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Username sudah digunakan'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 45),
                        ),
                        child: const Text('Perbarui'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> getLastActivity() async {
    try {
      if (username != null) {
        final temp = await FirebaseService().getLastActivity(username!);
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
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.white),
                ),
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
        _showErrorSnackBar('Error logging out: $e');
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
              'Poin',
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
              
              ...userbooked.map((booking) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(booking.date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: 15,
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
                      value: "${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}",
                    ),
                  ],
                ),
              )).toList(),
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
      return const Scaffold(
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
                            radius: 40,
                            backgroundColor:
                                isMember
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
                                  fontSize: 25,
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
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isMember)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '💎 Member',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
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
                  Positioned(
                    bottom: -45,
                    left: 20,
                    right: 20,
                    child: _buildStatsCard(),
                  ),
                ],
              ),

              const SizedBox(height: 55),

              // Membership status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Text(
                      isMember ? '💎' : '🪨',
                      style: const TextStyle(fontSize: 30),
                    ),
                    title: Text(
                      isMember ? 'Member' : 'Non Member',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle:
                        isMember
                            ? Text(
                              'Berakhir dalam ${endTime.toString()} hari',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                            : const Text(
                              'Upgrade untuk mendapatkan benefit lebih',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                    trailing:
                        isMember
                            ? null
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap:
                        isMember
                            ? () {
                              // Navigate to member schedule or details
                              showDialog(
                                context: context,
                                builder: (context) => _memberSchedule(),
                              ).then((_) => _init());
                            }
                            : () {
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
                    _buildRewardSection(context),
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
                                builder: (context) => editUsername(context),
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
                                builder: (context) => editPassword(context),
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
