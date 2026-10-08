// screens/admin/user_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import 'admin_home_screen.dart';
import 'restaurant_management_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<UserModel> _allUsers = [];
  List<UserModel> _regularUsers = [];
  List<UserModel> _owners = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));

      final allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to data
        return UserModel.fromMap(data);
      }).toList();

      final regularUsers = allUsers
          .where((user) => user.role == 'Pengguna')
          .toList();

      final owners = allUsers
          .where((user) => user.role == 'Pemilik Resto' || user.role == 'owner')
          .toList();

      if (mounted) {
        setState(() {
          _allUsers = allUsers;
          _regularUsers = regularUsers;
          _owners = owners;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Daftar Pengguna'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFFFE4D6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Pengguna'),
            Tab(text: 'Pemilik Resto'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsOverview(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserList(_allUsers),
                      _buildUserList(_regularUsers),
                      _buildUserList(_owners),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 1),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Semua User', '${_allUsers.length}', Colors.blue),
          _buildStatItem('Pengguna', '${_regularUsers.length}', Colors.green),
          _buildStatItem(
            'Pemilik Resto',
            '${_owners.length}',
            AppColors.primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pengguna',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  child: Icon(Icons.person, color: _getRoleColor(user.role)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.displayRole,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (user.phone != null && user.phone!.isNotEmpty)
              _buildDetailRow('Telepon', user.phone!),
            _buildDetailRow('Bergabung', _formatDate(user.createdAt)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewUserDetails(user),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Detail'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _contactUser(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Hubungi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Pemilik Resto':
      case 'owner':
        return Colors.blue;
      case 'Pengguna':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Pengguna'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogDetailRow('Username', user.username),
              _buildDialogDetailRow('Email', user.email),
              _buildDialogDetailRow('Role', user.displayRole),
              _buildDialogDetailRow('Telepon', user.phone ?? '-'),
              _buildDialogDetailRow('Bergabung', _formatDate(user.createdAt)),
              _buildDialogDetailRow('User ID', user.id),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _contactUser(UserModel user) {
    if (user.phone == null || user.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon tidak tersedia'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menghubungi ${user.username} di ${user.phone}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        _onBottomNavTap(context, index);
      },
      items: [
        BottomNavItem(icon: Icons.home, label: 'Home'),
        BottomNavItem(icon: Icons.people, label: 'Users'),
        BottomNavItem(icon: Icons.restaurant, label: 'Resto'),
      ],
    );
  }

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        );
        break;
      case 1: // Users - tetap di screen yang sama
        break;
      case 2: // Resto
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const RestaurantManagementScreen(),
          ),
        );
        break;
    }
  }
}
