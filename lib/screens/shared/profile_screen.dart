// screens/shared/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';
import '../user/list_screen.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _userStats = {
    'reservations': 0,
    'reviews': 0,
    'favorites': 0,
  };

  Map<String, dynamic> _ownerStats = {
    'restaurantCount': 0,
    'todayReservations': 0,
    'rating': 0.0,
  };

  Map<String, dynamic> _adminStats = {
    'totalUsers': 0,
    'totalRestaurants': 0,
    'pendingVerifications': 0,
  };

  // TAMBAHKAN VARIABLE INI
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  @override
  void dispose() {
    // Optional: Cancel any ongoing operations
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    // CHECK JIKA WIDGET SUDAH TIDAK MOUNTED
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
      return;
    }

    try {
      print(
        '🔄 Loading user stats for: ${user.username}, Role: "${user.role}", ID: ${user.id}',
      );

      if (user.role == 'Pengguna') {
        // Load customer stats
        final reservationSnapshot = await FirebaseFirestore.instance
            .collection('reservations')
            .where('userId', isEqualTo: user.id)
            .get()
            .timeout(const Duration(seconds: 10));

        final reviewSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: user.id)
            .get()
            .timeout(const Duration(seconds: 10));

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .get()
            .timeout(const Duration(seconds: 10));

        final favoritesList = userDoc.data()?['favorites'];
        final favorites = favoritesList is List ? favoritesList : [];

        print(
          '📊 User Stats - Reservations: ${reservationSnapshot.docs.length}, Reviews: ${reviewSnapshot.docs.length}, Favorites: ${favorites.length}',
        );

        if (!mounted) return;

        setState(() {
          _userStats = {
            'reservations': reservationSnapshot.docs.length,
            'reviews': reviewSnapshot.docs.length,
            'favorites': favorites.length,
          };
          _isLoadingStats = false;
        });
      } else if (user.role == 'Pemilik Resto') {
        // Load owner stats
        print('🔍 Querying restaurants with ownerId: ${user.id}');

        final restaurantSnapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .where('ownerId', isEqualTo: user.id)
            .get()
            .timeout(const Duration(seconds: 10));

        print('🔍 Found ${restaurantSnapshot.docs.length} restaurants');

        if (restaurantSnapshot.docs.isEmpty) {
          print('⚠️ No restaurants found for ownerId: ${user.id}');
          if (!mounted) return;
          setState(() {
            _ownerStats = {
              'restaurantCount': 0,
              'todayReservations': 0,
              'rating': 0.0,
            };
            _isLoadingStats = false;
          });
          return;
        }

        final restaurantCount = restaurantSnapshot.docs.length;
        final restaurant = restaurantSnapshot.docs.first;
        final restaurantId = restaurant.id;
        final restaurantData = restaurant.data();

        print(
          '✅ Restaurant found - ID: $restaurantId, Name: ${restaurantData['name']}',
        );

        // Get today's reservations
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
          59,
        );

        final reservationsSnapshot = await FirebaseFirestore.instance
            .collection('reservations')
            .where('restaurantId', isEqualTo: restaurantId)
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get()
            .timeout(const Duration(seconds: 10));

        final rating = restaurantData['rating'] ?? 0.0;

        print(
          '📊 Owner Stats - Restaurants: $restaurantCount, Today Reservations: ${reservationsSnapshot.docs.length}, Rating: $rating',
        );

        if (!mounted) return;

        setState(() {
          _ownerStats = {
            'restaurantCount': restaurantCount,
            'todayReservations': reservationsSnapshot.docs.length,
            'rating': rating is int ? rating.toDouble() : rating,
          };
          _isLoadingStats = false;
        });
      } else if (user.role == 'Admin') {
        // Load admin stats
        print('🔍 Loading admin stats...');

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

        // Count pending restaurant verifications
        final pendingRestaurantsSnapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .where('isVerified', isEqualTo: false)
            .get()
            .timeout(const Duration(seconds: 10));

        print(
          '📊 Admin Stats - Users: ${usersSnapshot.docs.length}, Restaurants: ${restaurantsSnapshot.docs.length}, Pending: ${pendingRestaurantsSnapshot.docs.length}',
        );

        if (!mounted) return;

        setState(() {
          _adminStats = {
            'totalUsers': usersSnapshot.docs.length,
            'totalRestaurants': restaurantsSnapshot.docs.length,
            'pendingVerifications': pendingRestaurantsSnapshot.docs.length,
          };
          _isLoadingStats = false;
        });
      } else {
        // Other roles
        if (!mounted) return;
        setState(() {
          _isLoadingStats = false;
        });
      }

      print('✅ User stats loaded successfully');
    } catch (e) {
      if (mounted) {
        print('❌ Error loading user stats: $e');
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      print('🔄 Starting logout process from ProfileScreen...');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Debug: Check state sebelum logout
      print('🔍 Before logout - User: ${authProvider.user?.username}');
      print(
        '🔍 Before logout - isAuthenticated: ${authProvider.isAuthenticated}',
      );

      await authProvider.logout();

      // Debug: Check state setelah logout
      print('🔍 After logout - User: ${authProvider.user}');
      print(
        '🔍 After logout - isAuthenticated: ${authProvider.isAuthenticated}',
      );

      // PERBAIKI: Gunakan Navigator yang berbeda
      print('🔄 Navigating to LoginScreen...');

      // Opsi 1: Gunakan Navigator global
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      print('✅ Navigation to LoginScreen completed');
    } catch (e) {
      print('❌ Logout error in ProfileScreen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? user = authProvider.user;

    // DEBUG: Print state
    if (user != null) {
      print('👤 ProfileScreen - User: ${user.username}, Role: ${user.role}');
    } else {
      print('👤 ProfileScreen - No user (might be during logout)');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading user...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header Profile
                  _buildProfileHeader(user),
                  const SizedBox(height: 32),

                  // Stats berdasarkan role
                  _buildUserStats(user.role),
                  const SizedBox(height: 32),

                  // Menu lainnya
                  _buildMenuItems(context, authProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(Icons.person, size: 40, color: AppColors.darkOrange),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.displayRole,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserStats(String role) {
    switch (role) {
      case 'Pengguna':
        return _buildUserStatsForCustomer();
      case 'Pemilik Resto':
        return _buildUserStatsForOwner();
      case 'Admin':
        return _buildUserStatsForAdmin();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUserStatsForCustomer() {
    // TAMBAHKAN LOADING STATE
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                title: 'Reservasi',
                value: _userStats['reservations'].toString(),
              ),
              _StatItem(
                title: 'Komentar',
                value: _userStats['reviews'].toString(),
              ),
              _StatItem(
                title: 'Favorit',
                value: _userStats['favorites'].toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsForOwner() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                title: 'Restoran',
                value: '${_ownerStats['restaurantCount']}',
              ),
              _StatItem(
                title: 'Reservasi\nHari Ini',
                value: '${_ownerStats['todayReservations']}',
              ),
              _StatItem(
                title: 'Rating',
                value: (_ownerStats['rating'] as double).toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsForAdmin() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(title: 'User', value: '${_adminStats['totalUsers']}'),
              _StatItem(
                title: 'Restoran',
                value: '${_adminStats['totalRestaurants']}',
              ),
              _StatItem(
                title: 'Pending',
                value: '${_adminStats['pendingVerifications']}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.user;

    return Column(
      children: [
        _MenuCard(
          icon: Icons.edit,
          title: 'Edit Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
        ),
        // Riwayat Reservasi hanya untuk Pengguna (bukan untuk Owner atau Admin)
        if (user?.role == 'Pengguna')
          _MenuCard(
            icon: Icons.history,
            title: 'Riwayat Reservasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListScreen()),
              );
            },
          ),
        _MenuCard(
          icon: Icons.settings,
          title: 'Pengaturan',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        _MenuCard(
          icon: Icons.help,
          title: 'Bantuan',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            );
          },
        ),
        const SizedBox(height: 20),
        // Logout Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _showLogoutConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => _performLogout(context),
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Pemilik Resto':
        return Colors.blue;
      case 'Pengguna':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Widget untuk stat item
class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryOrange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// Widget untuk menu card
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryOrange),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
