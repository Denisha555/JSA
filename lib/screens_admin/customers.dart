import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens_admin/daftar_member.dart';
import 'package:flutter_application_1/screens_admin/daftar_non_member.dart';
import 'package:flutter_application_1/screens_pelanggan/member.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
    _init();
  }

  void _init() {
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await FirebaseService().getAllUsers();
      _processUsers(users);
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  void _processUsers(List<dynamic> allUsers) {
    final Map<String, Map<String, String>> tempData = {};
    for (var user in allUsers) {
      final role = user.role ?? '';
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Customers"),

          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
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
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  children: [
                    _buildUserList('member'),
                    _buildUserList('nonMember'),
                  ],
                ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => _choseseAction(),
            );
          },
          backgroundColor: primaryColor,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUserList(String status) {
    final filteredUsers =
        userdata.entries
            .where((entry) => entry.value['status'] == status)
            .map((entry) => _buildUserCard(entry.key, status))
            .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchUsers();
      },
      child:
          filteredUsers.isEmpty
              ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      'Belum ada data',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              )
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) => filteredUsers[index],
              ),
    );
  }

  Widget _buildUserCard(String username, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  status == 'member' ? Colors.blueAccent : Colors.grey[400],
              child: Text(
                username[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choseseAction() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Jenis Akun yang ingin ditambahkan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: const Text('Member'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanMemberAdmin(),
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Non Member'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanNonMemberAdmin(),
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
