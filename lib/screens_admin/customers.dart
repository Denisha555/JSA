import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens_admin/daftar_member.dart';
import 'package:flutter_application_1/screens_admin/daftar_non_member.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/constants_file.dart';

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

  // Data fetching methods
  Future<void> _fetchUsers() async {
    try {
      final users = await FirebaseService().getAllUsers();
      _processUsers(users);
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar('Gagal memuat data: $e');
      }
    }
  }

  void _processUsers(List<dynamic> allUsers) {
    final Map<String, Map<String, String>> tempData = {};
    
    for (var user in allUsers) {
      final role = user.role ?? '';
      
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Navigation methods
  void _navigateToUserInfo(String username) async {
    try {
      List<UserData> userdata = await FirebaseService().getUserData(username);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildUserInfoDialog(userdata),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memuat informasi pengguna: $e');
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildAddUserDialog(),
    );
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
      children: [
        _buildUserList('member'),
        _buildUserList('nonMember'),
      ],
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
    final filteredUsers = userdata.entries
        .where((entry) => entry.value['status'] == status)
        .map((entry) => _buildUserCard(entry.key, status))
        .toList();

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: filteredUsers.isEmpty
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
    );
  }

  // User avatar widget
  Widget _buildUserAvatar(String username, String status) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: status == 'member' ? Colors.blueAccent : Colors.grey[400],
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${status == 'member' ? 'Member' : 'Non Member'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // User info dialog
  Widget _buildUserInfoDialog(List<UserData> userdata) {
    if (userdata.isEmpty) {
      return _buildErrorDialog('Data pengguna tidak ditemukan');
    }

    final user = userdata[0];
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Informasi Pengguna',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildUserInfoRow('Username', user.username),
            _buildUserInfoRow('Club', user.club),
            _buildUserInfoRow('No Telepon', user.noTelp),
            _buildUserInfoRow('Waktu Mulai', user.startTime),
            _buildUserInfoRow('Point', user.totalBooking.toString()),
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
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // Error dialog
  Widget _buildErrorDialog(String message) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Jenis Akun',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'yang ingin ditambahkan',
              style: TextStyle(fontSize: 16),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
      MaterialPageRoute(
        builder: (context) => const HalamanMemberAdmin(),
      ),
    );
  }

  void _navigateToAddNonMember() {
    Navigator.of(context).pop(); // Close dialog first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HalamanNonMemberAdmin(),
      ),
    );
  }
}