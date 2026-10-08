// screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_management_screen.dart';
import 'problematic_accounts_screen.dart';
import 'problematic_restaurants_screen.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _currentFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilterAndSearch();
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromMap(data);
      }).toList();

      if (mounted) {
        setState(() {
          _users = users;
          _applyFilterAndSearch();
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

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      _applyFilterAndSearch();
    });
  }

  void _applyFilterAndSearch() {
    List<UserModel> filtered = [];

    // Apply role/status filter
    switch (_currentFilter) {
      case 'all':
        filtered = _users;
        break;
      case 'active':
        filtered = _users.where((u) => u.status == 'active').toList();
        break;
      case 'suspended':
        filtered = _users.where((u) => u.status == 'suspended').toList();
        break;
      case 'user':
        filtered = _users.where((u) => u.role == 'Pengguna').toList();
        break;
      case 'owner':
        filtered = _users
            .where((u) => u.role == 'Pemilik Resto' || u.role == 'owner')
            .toList();
        break;
      default:
        filtered = _users;
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final username = user.username.toLowerCase();
        final email = user.email.toLowerCase();
        return username.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList();
    }

    _filteredUsers = filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Quick Actions - Akun & Resto Bermasalah
                    _buildQuickActions(),

                    const SizedBox(height: 16),

                    // Search and Filter
                    _buildSearchFilter(),

                    const SizedBox(height: 16),

                    // Users List
                    Expanded(child: _buildUsersList()),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(context, 1),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        // Akun Bermasalah
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProblematicAccountsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_off, color: Colors.red[700], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Akun\nBermasalah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Resto Bermasalah
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProblematicRestaurantsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightOrange),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    color: AppColors.darkOrange,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Resto\nBermasalah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryOrange, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pengguna...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryOrange),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          onSelected: (value) {
            _applyFilter(value);
          },
          icon: const Icon(Icons.filter_list),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'all', child: Text('Semua Pengguna')),
            const PopupMenuItem(value: 'active', child: Text('Aktif')),
            const PopupMenuItem(
              value: 'suspended',
              child: Text('Ditangguhkan'),
            ),
            const PopupMenuItem(value: 'user', child: Text('Pengguna Biasa')),
            const PopupMenuItem(value: 'owner', child: Text('Pemilik Resto')),
          ],
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
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

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_filteredUsers[index]);
      },
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
            // User Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    color: _getStatusColor(user.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(user.status),
                    style: TextStyle(
                      color: _getStatusColor(user.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // User Details
            _buildUserDetail('Role', user.displayRole),
            _buildUserDetail('Bergabung', _formatDate(user.createdAt)),
            _buildUserDetail('Jumlah Ulasan', '${user.reviewCount} ulasan'),
            if (user.phone != null && user.phone!.isNotEmpty)
              _buildUserDetail('Telepon', user.phone!),

            const SizedBox(height: 12),

            // Action Buttons
            _buildActionButtons(user),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetail(
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isWarning ? AppColors.primaryOrange : Colors.black,
                fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UserModel user) {
    return Row(
      children: [
        if (user.status == 'active') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _viewUserDetails(user);
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Lihat Detail'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _suspendUser(user);
              },
              icon: const Icon(Icons.warning, size: 16),
              label: const Text('Tangguhkan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else if (user.status == 'suspended') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _viewUserDetails(user);
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Lihat Detail'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _activateUser(user);
              },
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Aktifkan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
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
              _buildUserDetailDialog('Username', user.username),
              _buildUserDetailDialog('Email', user.email),
              _buildUserDetailDialog('Role', user.displayRole),
              _buildUserDetailDialog('Status', _getStatusText(user.status)),
              _buildUserDetailDialog('Bergabung', _formatDate(user.createdAt)),
              _buildUserDetailDialog('Jumlah Ulasan', '${user.reviewCount}'),
              _buildUserDetailDialog('Favorit', '${user.favoriteCount}'),
              if (user.phone != null && user.phone!.isNotEmpty)
                _buildUserDetailDialog('Telepon', user.phone!),
              _buildUserDetailDialog('User ID', user.id),
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

  Widget _buildUserDetailDialog(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  void _suspendUser(UserModel user) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Tangguhkan Pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tangguhkan ${user.username}?'),
            const SizedBox(height: 8),
            const Text('Alasan penangguhan:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Memberi rating buruk 10x berturut-turut',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.id)
                      .update({
                        'status': 'suspended',
                        'suspensionReason': reasonController.text,
                        'updatedAt': Timestamp.now(),
                      });

                  Navigator.pop(context);
                  await _loadUsers(); // Reload data

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pengguna berhasil ditangguhkan'),
                        backgroundColor: AppColors.primaryOrange,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Error suspending user: $e');
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal menangguhkan pengguna'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tangguhkan'),
          ),
        ],
      ),
    );
  }

  void _activateUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Pengguna'),
        content: Text(
          'Apakah Anda yakin ingin mengaktifkan kembali ${user.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .update({
                      'status': 'active',
                      'suspensionReason': FieldValue.delete(),
                      'updatedAt': Timestamp.now(),
                    });

                Navigator.pop(context);
                await _loadUsers(); // Reload data

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengguna berhasil diaktifkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error activating user: $e');
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal mengaktifkan pengguna'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return AppColors.primaryOrange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'suspended':
        return 'Ditangguhkan';
      default:
        return status;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; // Sudah di screen ini

        switch (index) {
          case 0: // Home
            Navigator.pop(context); // Kembali ke home
            break;
          case 1: // Users - tetap di screen ini
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
      },
      items: [
        BottomNavItem(icon: Icons.home, label: 'Home'),
        BottomNavItem(icon: Icons.people, label: 'Users'),
        BottomNavItem(icon: Icons.restaurant, label: 'Resto'),
      ],
    );
  }
}
