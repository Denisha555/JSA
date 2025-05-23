import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens_pelanggan/member.dart';
import 'package:flutter_application_1/screens_pelanggan/pilih_halaman_pelanggan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/screens_pelanggan/halaman_utama_pelanggan.dart';

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
        final result = await FirebaseService().memberOrNonmember(username!);

        if (!mounted) return;

        setState(() {
          isMember = result;
        });

        await getLastActivity();
        final Reward currentReward = Reward(currentHours: 6);
      }
    } catch (e) {
      debugPrint('Error initializing profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
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
    });
  }

  Widget _buildRewardSection(BuildContext context) {
    double progress = (currentReward.currentHours / currentReward.requiredHours)
        .clamp(0.0, 1.0);

    // Calculate next stage hours (every 10 hours)
    double nextStageHours =
        ((currentReward.currentHours / 10).floor() + 1) * 10;

    if (nextStageHours > currentReward.requiredHours) {
      nextStageHours = currentReward.requiredHours;
    }

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
              double nextMarkerPos =
                  nextStageHours / currentReward.requiredHours * barWidth;

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
                  // Marker for next reward stage
                  Positioned(
                    left: nextMarkerPos - 5,
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

          // Description text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentReward.currentHours.toInt()}h played',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '${(nextStageHours - currentReward.currentHours).clamp(0, double.infinity).toInt()}h to next reward',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateUsername(String newUsername) async {
    try {
      if (username != null && newUsername.isNotEmpty) {
        await FirebaseService().editUsername(username!, newUsername);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', newUsername);

        // Update the username in state
        setState(() {
          username = newUsername;
        });

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!')),
        );

        // Close dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating username: $e')));
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      if (username != null && newPassword.isNotEmpty) {
        await FirebaseService().editPassword(username!, newPassword);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('password', newPassword);

        if (!mounted) return;
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );

        // Close dialog
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating password: $e')));
    }
  }

  Widget editUsername(BuildContext context) {
    TextEditingController usernameController = TextEditingController();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ubah Username',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: 'Input username baru',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _updateUsername(usernameController.text);
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setString('username', usernameController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 45),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget editPassword(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    TextEditingController passwordController2 = TextEditingController();
    bool obscureText = true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: SingleChildScrollView(
        // Scrollable content
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ubah Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: 'Input password baru',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController2,
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: 'Konfirmasi password baru',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (passwordController.text.isEmpty || passwordController2.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password tidak boleh kosong')),
                      ); 
                      return;
                    } else if (passwordController.text == passwordController2.text) {
                      _updatePassword(passwordController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password tidak sama')),
                      );
                      return;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 45),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getLastActivity() async {
    try {
      if (username != null) {
        final temp = await FirebaseService().getLastActivity(username!);
        if (temp.isNotEmpty) {
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
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah kamu yakin ingin logout?'),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(context, false), // Tidak jadi logout
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true), // Lanjut logout
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    // Kalau pengguna setuju untuk logout
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                    height: 180,
                    padding: const EdgeInsets.only(
                      top: 25,
                      right: 20,
                      left: 20,
                    ),
                    decoration: BoxDecoration(color: primaryColor),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor:
                              isMember ? Colors.blueAccent : Colors.grey[400]!,
                          child: Text(
                            username![0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
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
                            Text(
                              '${data.isNotEmpty ? data[0].totalHour.toStringAsFixed(1) : 0} Poin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: 20,
                    right: 20,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.grey[100],
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${data.isNotEmpty ? data[0].totalBooking.toString() : 0}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Booking', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${data.isNotEmpty ? data[0].totalHour.toStringAsFixed(1) : 0}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Poin', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 55),

              // Membership status
              Padding(
                padding: const EdgeInsets.only(right: 20.0, left: 20.0),
                child:
                    isMember
                        ? GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: const [
                              Text('💎', style: TextStyle(fontSize: 30)),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Member',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Berakhir dalam 30 hari',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        : GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HalamanMember(),
                              ),
                            ).then((_) => _init());
                          },
                          child: Row(
                            children: const [
                              Text('🪨', style: TextStyle(fontSize: 30)),
                              SizedBox(width: 10),
                              Text(
                                'Non Member',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),

              const SizedBox(height: 20),

              // Activity history section
              Padding(
                padding: const EdgeInsets.only(right: 20.0, left: 20),
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
                    const Divider(),

                    activity.isEmpty
                        ? GestureDetector(
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
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 25),
                              SizedBox(width: 10),
                              Text('Belum Ada Aktivitas'),
                            ],
                          ),
                        )
                        : GestureDetector(
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
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 25),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booked Court - Lapangan ${activity[0].courtId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(activity[0].date),
                                ],
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reward progress section
              Padding(
                padding: const EdgeInsets.only(right: 20, left: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progres',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 5),
                    _buildRewardSection(context),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile management section
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.edit, size: 20),
                      title: const Text('Edit Profil'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => editUsername(context),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock, size: 20),
                      title: const Text('Ubah Password'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => editPassword(context),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout_sharp, size: 20),
                      title: const Text('Log Out'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
