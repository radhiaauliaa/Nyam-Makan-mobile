// screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../shared/profile_screen.dart';
import 'restaurant_management_screen.dart';
import 'user_management_screen.dart';
import 'user_list_screen.dart';
import 'verification_screen.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/restaurant_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_service.dart';
import '../shared/notifications_screen.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _totalUsers = 0;
  int _totalRestaurants = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      print('🔄 Loading admin stats...');

      // Count total users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));

      // Count total restaurants
      final restaurantsSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .get()
          .timeout(const Duration(seconds: 10));

      print(
        '📊 Admin Stats - Users: ${usersSnapshot.docs.length}, Restaurants: ${restaurantsSnapshot.docs.length}',
      );

      if (mounted) {
        setState(() {
          _totalUsers = usersSnapshot.docs.length;
          _totalRestaurants = restaurantsSnapshot.docs.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('❌ Error loading admin stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // NOTIFICATION LISTENER
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (userId != null) {
        notifProvider.listenToUnreadCount(userId);
      }
    });
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          const SizedBox(height: 24),

          // Content with padding
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Overview
                  _buildStatsOverview(),

                  const SizedBox(height: 24),

                  // Title for Management Sections
                  const Text(
                    'Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Management Sections
                  _buildManagementSections(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset('assets/nyam_makaan.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Admin!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Nyam! Makaan',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Notification Badge with FCM
          Builder(
            builder: (context) {
              final userId = Provider.of<AuthProvider>(
                context,
                listen: false,
              ).user?.id;
              if (userId == null) return const SizedBox.shrink();

              return StreamBuilder<int>(
                stream: FCMService.getUnreadNotificationsCount(userId),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotificationsScreen(userId: userId),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Loading stats...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelola Aplikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Pengguna',
                '$_totalUsers',
                Icons.people,
                Colors.blue,
              ),
              _buildStatItem(
                'Total Merchant',
                '$_totalRestaurants',
                Icons.restaurant,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildManagementSections(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Management
          _buildManagementSection(
            'Manajemen Pengguna',
            Icons.people,
            Colors.blue,
            [
              _buildManagementItem(
                'Daftar Pengguna',
                'Lihat semua pengguna dan pemilik resto',
                Icons.list,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserListScreen(),
                    ),
                  );
                },
              ),
              _buildManagementItem(
                'Kelola Pengguna',
                'Tangguhkan atau aktifkan user',
                Icons.manage_accounts,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  );
                },
              ),
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserListScreen()),
              );
            },
          ),

          const SizedBox(height: 16),

          // Restaurant Management - PERBAIKAN: Gunakan Consumer untuk akses provider
          Consumer<RestaurantProvider>(
            builder: (context, provider, child) {
              return _buildManagementSection(
                'Manajemen Restoran',
                Icons.restaurant,
                Colors.green,
                [
                  _buildManagementItem(
                    'Daftar Resto Baru',
                    '${provider.pendingRestaurants.length} resto menunggu verifikasi',
                    Icons.list,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RestaurantManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildManagementItem(
                    'Verifikasi Resto Baru',
                    'Proses pendaftaran resto',
                    Icons.verified,
                    onTap: () {
                      // Navigate to first pending restaurant or show list
                      if (provider.pendingRestaurants.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerificationScreen(
                              restaurant: _convertRestaurantToMap(
                                provider.pendingRestaurants.first,
                              ),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tidak ada restoran yang menunggu verifikasi',
                            ),
                            backgroundColor: AppColors.primaryOrange,
                          ),
                        );
                      }
                    },
                  ),
                  _buildManagementItem(
                    'Kelola Resto',
                    'Lihat dan kelola semua resto',
                    Icons.manage_search,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RestaurantManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestaurantManagementScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // PERBAIKAN: Pindahkan method helper ke luar _buildManagementSections
  Map<String, dynamic> _convertRestaurantToMap(Restaurant restaurant) {
    return {
      'id': restaurant.id,
      'name': restaurant.name,
      'category': restaurant.categories.isNotEmpty
          ? restaurant.categories.first
          : '',
      'ownerId': restaurant.ownerId, // ID pemilik untuk fetch data
      'ownerEmail': restaurant.ownerEmail, // Email pemilik
      'owner':
          restaurant.owner ??
          restaurant.ownerId ??
          'Tidak diketahui', // Nama pemilik
      'phone': restaurant.phone,
      'address': restaurant.address,
      'openTime': restaurant.openTime,
      'closeTime': restaurant.closeTime,
      'description': restaurant.description,
      'images': restaurant.images,
      'licenseUrl': restaurant.license,
      'submissionDate': _formatDate(restaurant.createdAt ?? DateTime.now()),
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildManagementSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> items, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildManagementItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        ),
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
      case 0: // Home - tetap di screen yang sama
        break;
      case 1: // Users
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserManagementScreen()),
        );
        break;
      case 2: // Resto
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RestaurantManagementScreen(),
          ),
        );
        break;
    }
  }
}
