import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants_file.dart';
import 'package:flutter_application_1/model/user_model.dart';
import 'package:flutter_application_1/function/snackbar/snackbar.dart';
import 'package:flutter_application_1/screens_admin/daftar_member.dart';
import 'package:flutter_application_1/screens_admin/daftar_non_member.dart';
import 'package:flutter_application_1/services/user/firebase_check_user.dart';
import 'package:flutter_application_1/services/user/firebase_update_user.dart';
import 'package:flutter_application_1/services/user/firebase_get_user.dart';

class HalamanCustomers extends StatefulWidget {
  final int tabIndex;
  const HalamanCustomers({super.key, this.tabIndex = 0});

  @override
  State<HalamanCustomers> createState() => _HalamanCustomersState();
}

class _HalamanCustomersState extends State<HalamanCustomers> {
  Map<String, Map<String, String>> userdata = {};
  bool isLoading = true;

  late int currentTab;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    currentTab = widget.tabIndex;
  }

  Future<void> _fetchUsers() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final users = await FirebaseGetUser().getUsers();
      _processUsers(users);
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showErrorSnackBar(context, 'Gagal memuat data: $e');
      }
    }
  }

  void _processUsers(List<UserModel> allUsers) {
    final Map<String, Map<String, String>> tempData = {};
    for (var user in allUsers) {
      if (user.role == 'admin' || user.role == 'owner') continue;
      tempData[user.username] = {
        'status': (user.role == 'member') ? 'member' : 'nonMember',
      };
    }

    setState(() {
      userdata = tempData;
      isLoading = false;
    });
  }

  void _navigateToUserInfo(String username) async {
    // Tampilkan loading indicator saat fetch
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
    );
    try {
      await FirebaseCheckUser().checkMembership(username);
      await FirebaseCheckUser().checkUserPoint(username);
      final users = await FirebaseGetUser().getUserByUsername(username);
      if (!mounted) return;
      Navigator.of(context).pop(); // tutup loading
      _showUserInfoSheet(users);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showErrorSnackBar(context, 'Gagal memuat informasi pengguna: $e');
    }
  }

  // ✅ Bottom sheet — lebih modern dari dialog
  void _showUserInfoSheet(List<UserModel> users) {
    if (users.isEmpty) return;
    final user = users[0];
    final isMember = user.role == 'member';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Avatar + nama
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          isMember ? Colors.blueAccent : Colors.grey[400],
                      child: Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          
                          decoration: BoxDecoration(
                            color:
                                isMember ? Colors.blue[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            isMember ? 'Member' : 'Non Member',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  isMember
                                      ? Colors.blue[800]
                                      : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                _buildInfoRow('Club', user.club == "" ? "-" : user.club),
                _buildInfoRow(
                  'No. Telepon',
                  user.noTelp == "" ? "-" : user.noTelp,
                ),
                _buildInfoRow(
                  'Mulai point',
                  user.startTimePoint == "" ? "-" : user.startTimePoint,
                ),
                _buildInfoRow(
                  'Mulai member',
                  user.startTimeMember == "" ? "-" : user.startTimeMember,
                ),
                _buildInfoRow(
                  'Poin',
                  user.point.toString() == "" ? "0" : user.point.toString(),
                ),
                _buildInfoRow(
                  'Cancel',
                  user.cancel.toString() == "" ? "0" : user.cancel.toString(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Hapus pengguna?'),
            content: Text('$username akan dihapus secara permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  // await FirebaseDeleteUser().deleteUser(username);
                  await FirebaseUpdateUser().updateUser("status", username, "nonaktif");
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
    if (confirmed == true) _fetchUsers();
    return confirmed ?? false;
  }

  Future<bool> _showEditDialog(BuildContext context, String username) async {
    List<UserModel> users;
    try {
      users = await FirebaseGetUser().getUserByUsername(username);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Gagal memuat data: $e');
      return false;
    }
    if (users.isEmpty) return false;
    final user = users[0];

    final clubController = TextEditingController(text: user.club);
    final notelpController = TextEditingController(text: user.noTelp);
    final waktuPointController = TextEditingController(
      text: user.startTimePoint.toString(),
    );
    final waktuMemberController = TextEditingController(
      text: user.startTimeMember.toString(),
    );
    final pointController = TextEditingController(text: user.point.toString());
    final cancelController = TextEditingController(
      text: user.cancel.toString(),
    );
    final _formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Edit pengguna',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.username,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: clubController,
                      decoration: _inputDecor('Club'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notelpController,
                      decoration: _inputDecor('No. Telepon'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'No. Telepon tidak boleh kosong';
                        } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'No. Telepon hanya boleh berisi angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;
                              await FirebaseUpdateUser().updateManyData({
                                "club": clubController.text,
                                "phoneNumber": notelpController.text,
                              }, username);
                              Navigator.of(ctx).pop(true);
                              showSuccessSnackBar(context, "Data berhasil diubah");
                            },
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    clubController.dispose();
    notelpController.dispose();
    waktuPointController.dispose();
    waktuMemberController.dispose();
    pointController.dispose();
    cancelController.dispose();

    if (saved == true) _fetchUsers();
    return false;
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: currentTab,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Pelanggan"),
      bottom: const TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            child: Text(
              "Member",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Tab(
            child: Text(
              "Non Member",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return _buildSkeletonList();
    return TabBarView(
      children: [_buildUserList('member'), _buildUserList('nonMember')],
    );
  }

  // ✅ Skeleton loading — lebih elegan dari spinner
  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder:
          (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _skeletonBox(42, 42, radius: 21),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeletonBox(12, double.infinity),
                        const SizedBox(height: 8),
                        _skeletonBox(10, 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _skeletonBox(double height, double width, {double radius = 6}) {
    return Container(
      height: height,
      width: width == double.infinity ? null : width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddUserSheet,
      backgroundColor: primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // ✅ Bottom sheet untuk tambah user
  void _showAddUserSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Pilih jenis akun',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _buildAddOption(
                  title: 'Member',
                  subtitle: 'Akun dengan keanggotaan aktif',
                  icon: Icons.person,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HalamanMemberAdmin(),
                      ),
                    ).then((_) {
                      if (mounted) _fetchUsers();
                    });
                  },
                ),
                const SizedBox(height: 10),
_buildAddOption(
  title: 'Non Member',
  subtitle: 'Akun tanpa keanggotaan',
  icon: Icons.person_outline,
  onTap: () async {
    Navigator.pop(ctx);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HalamanNonMemberAdmin(),
      ),
    );

    if (mounted) {
      _fetchUsers();
    }

    if (result != null) {
      setState(() {
        currentTab = result;
      });
    }
  },
),
              ],
            ),
          ),
    );
  }

  Widget _buildAddOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String status) {
    final filtered =
        userdata.entries.where((e) => e.value['status'] == status).toList();

    final count = filtered.length;

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child:
          filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '$count ${status == 'member' ? 'member' : 'non member'} aktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  final entry = filtered[index - 1];
                  return _buildUserCard(entry.key, status);
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Belum ada data',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(String username, String status) {
    final isMember = status == 'member';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(username),
        direction: DismissDirection.horizontal,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return await _showDeleteDialog(context, username);
          } else {
            return await _showEditDialog(context, username);
          }
        },
        child: GestureDetector(
          onTap: () => _navigateToUserInfo(username),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      isMember ? Colors.blueAccent : Colors.grey[400],
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isMember ? Colors.blue[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          isMember ? 'Member' : 'Non Member',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color:
                                isMember ? Colors.blue[800] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[300], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
