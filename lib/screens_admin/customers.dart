import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/user_model.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/screens_admin/daftar_member.dart';
import 'package:flutter_application_1/screens_admin/daftar_non_member.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';
import 'package:flutter_application_1/services/user/firebase_delete_user.dart';


class HalamanCustomers extends StatefulWidget {
  const HalamanCustomers({super.key});

  @override
  State<HalamanCustomers> createState() => _HalamanCustomersState();
}

class _HalamanCustomersState extends State<HalamanCustomers> {
  Map<String, Map<String, String>> userdata = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Data fetching method
  Future<void> _fetchUsers() async {
    try {
      final users = await FirebaseGetUser().getUsers();
      _processUsers(users);
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        showErrorSnackBar(context, 'Gagal memuat data: $e');
      }
    }
  }

  void _processUsers(List<UserModel> allUsers) {
    final Map<String, Map<String, String>> tempData = {};

    for (var user in allUsers) {
      final role = user.role;

      // Skip admin and owner roles
      if (role == 'admin' || role == 'owner') {
        continue;
      }

      final status = (role == 'member') ? 'member' : 'nonMember';
      tempData[user.username] = {'status': status};
    }

    if (mounted) {
      setState(() {
        userdata = tempData;
        isLoading = false;
      });
    }
  }

  // Navigation methods
  void _navigateToUserInfo(String username) async {
    try {
      await FirebaseCheckUser().checkMembership(username);
      await FirebaseCheckUser().checkRewardTime(username);
      List<UserModel> userdata = await FirebaseGetUser().getUserByUsername(
        username,
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildUserInfoDialog(userdata),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Gagal memuat informasi pengguna: $e');
    }
  }

  void _showAddUserDialog() {
    showDialog(context: context, builder: (context) => _buildAddUserDialog());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  // AppBar widget
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Customers"),
      bottom: const TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            child: Text(
              "Member",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Tab(
            child: Text(
              "Non Member",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Body widget
  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      children: [_buildUserList('member'), _buildUserList('nonMember')],
    );
  }

  // FloatingActionButton widget
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showAddUserDialog,
      backgroundColor: primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // User list widget
  Widget _buildUserList(String status) {
    final filteredUsers =
        userdata.entries
            .where((entry) => entry.value['status'] == status)
            .map((entry) => _buildUserCard(entry.key, status))
            .toList();

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child:
          filteredUsers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) => filteredUsers[index],
              ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 100),
        Center(
          child: Text(
            'Belum ada data',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // User card widget
  Widget _buildUserCard(String username, String status) {
    return GestureDetector(
      onTap: () => _navigateToUserInfo(username),
      child: Dismissible(
        key: Key(username),
        direction: DismissDirection.horizontal,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.green),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.red),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Konfirmasi Hapus'),
                  content: Text(
                    'Apakah Anda yakin ingin menghapus pengguna $username?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    TextButton(
                      child: const Text('Hapus'),
                      onPressed: () async {
                        await FirebaseDeleteUser().deleteUser(username);
                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                        _fetchUsers();
                      },
                    ),
                  ],
                );
              },
            );
          } else if (direction == DismissDirection.startToEnd) {
            List<UserModel> userData = await FirebaseGetUser()
                .getUserByUsername(username);

            return await showDialog(
              context: context,
              builder: (context) {
                var clubController = TextEditingController(
                  text: userData[0].club,
                );
                var notelpController = TextEditingController(
                  text: userData[0].noTelp,
                );
                var waktuMulaiPointController = TextEditingController(
                  text: userData[0].startTimePoint.toString(),
                );
                var waktuMulaiMemberController = TextEditingController(
                  text: userData[0].startTimeMember.toString(),
                );
                var pointController = TextEditingController(
                  text: userData[0].point.toString(),
                );
                var cancelController = TextEditingController(
                  text: userData[0].cancel.toString(),
                );

                return AlertDialog(
                  title: const Text(
                    'Edit Pengguna',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Username : ${userData[0].username}',
                        style: TextStyle(fontSize: 15),
                      ),
                      TextField(
                        controller: clubController,
                        decoration: const InputDecoration(labelText: 'Club'),
                      ),
                      TextField(
                        controller: notelpController,
                        decoration: const InputDecoration(
                          labelText: 'No. Telepon',
                        ),
                      ),
                      TextField(
                        controller: waktuMulaiPointController,
                        decoration: const InputDecoration(
                          labelText: 'Waktu Mulai (Point)',
                        ),
                      ),
                      TextField(
                        controller: waktuMulaiMemberController,
                        decoration: const InputDecoration(
                          labelText: 'Waktu Mulai (Member)',
                        ),
                      ),
                      TextField(
                        controller: pointController,
                        decoration: const InputDecoration(labelText: 'Point'),
                      ),
                      TextField(
                        controller: cancelController,
                        decoration: const InputDecoration(labelText: 'Cancel'),
                      )
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Tutup'),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                );
              },
            );
          }
          return Future.value(false);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // sama dengan background
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildUserAvatar(username, status),
                  const SizedBox(width: 16),
                  _buildUserInfo(username, status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // User avatar widget
  Widget _buildUserAvatar(String username, String status) {
    return CircleAvatar(
      radius: 24,
      backgroundColor:
          status == 'member' ? Colors.blueAccent : Colors.grey[400],
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // User info widget
  Widget _buildUserInfo(String username, String status) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${status == 'member' ? 'Member' : 'Non Member'}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // User info dialog
  Widget _buildUserInfoDialog(List<UserModel> userdata) {
    if (userdata.isEmpty) {
      return _buildErrorDialog('Data pengguna tidak ditemukan');
    }

    final user = userdata[0];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Informasi Customer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildUserInfoRow('Username', user.username),
            _buildUserInfoRow('Club', user.club),
            _buildUserInfoRow('No Telepon', user.noTelp),
            _buildUserInfoRow('Waktu Mulai (point)', user.startTimePoint),
            _buildUserInfoRow('Waktu Mulai (member)', user.startTimeMember),
            _buildUserInfoRow('Poin', user.totalBooking.toString()),
            _buildUserInfoRow('Cancel', user.cancel.toString()),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // User info row widget
  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Error dialog
  Widget _buildErrorDialog(String message) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  // Add user dialog
  Widget _buildAddUserDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Jenis Akun',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildAddUserOption(
              'Member',
              Icons.person,
              () => _navigateToAddMember(),
            ),
            const SizedBox(height: 10),
            _buildAddUserOption(
              'Non Member',
              Icons.person_outline,
              () => _navigateToAddNonMember(),
            ),
          ],
        ),
      ),
    );
  }

  // Add user option widget
  Widget _buildAddUserOption(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToAddMember() {
    Navigator.of(context).pop(); // Close dialog first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HalamanMemberAdmin()),
    );
  }

  void _navigateToAddNonMember() {
    Navigator.of(context).pop(); // Close dialog first
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HalamanNonMemberAdmin()),
    );
  }
}
