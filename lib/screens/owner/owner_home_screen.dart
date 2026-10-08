// screens/owner/owner_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../../models/restaurant_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/profile_screen.dart';
import '../shared/restaurant_map_screen.dart';
import 'restaurant_register_screen.dart';
import 'edit_restaurant_screen.dart';
import 'manage_menu_screen.dart';
import 'manage_reservation_screen.dart';
import 'view_reviews_screen.dart';
import 'payment_settings_screen.dart';
import '../../providers/notification_provider.dart';
import '../../services/fcm_service.dart';
import '../shared/notifications_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  bool _loaded = false;
  bool _dataLoaded = false;
  int _todayReservationCount = 0;
  int _menuCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final rp = Provider.of<RestaurantProvider>(context, listen: false);
      
      if (auth.user != null) {
        // Listen untuk perubahan restaurant
        rp.addListener(() {
          if (rp.currentRestaurant != null && mounted) {
            _loadTodayReservations(rp.currentRestaurant!.id);
            _loadMenuCount(rp.currentRestaurant!.id);
          }
        });
        
        // Load restaurant pertama kali
        rp.loadCurrentRestaurant(auth.user!.id).then((_) {
          if (rp.currentRestaurant != null && mounted) {
            _loadTodayReservations(rp.currentRestaurant!.id);
            _loadMenuCount(rp.currentRestaurant!.id);
          }
        });

        // NOTIFICATION LISTENER
        final notifProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        notifProvider.listenToUnreadCount(auth.user!.id);
      }
      _loaded = true;
    }
  }

  int _currentIndex = 0;

  // Tambahkan method ini
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      // Menu
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ManageMenuScreen()),
      ).then((_) {
        setState(() {
          _currentIndex = 0;
        });
      });
    } else if (index == 2) {
      // Reservasi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManageReservationScreen(),
        ),
      ).then((_) {
        setState(() {
          _currentIndex = 0;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Setup listener untuk ketika kembali ke screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRefreshListener();
    });
  }

  void _setupRefreshListener() {
    // Listen to route changes (when returning from other screens)
    final routeObserver = ModalRoute.of(context);
    if (routeObserver != null) {
      routeObserver.addScopedWillPopCallback(() {
        return Future.value(true);
      });
      
      // Check if we're coming back from another screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          _refreshData();
        }
      });
    }
  }

  @override
  void dispose() {
    // Cancel listener jika ada
    final rp = context.read<RestaurantProvider>();
    rp.removeListener(() {}); // Hapus listener yang ditambahkan
    
    super.dispose();
  }

  Future<void> _refreshData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final rp = Provider.of<RestaurantProvider>(context, listen: false);
    
    if (auth.user != null && rp.currentRestaurant != null) {
      setState(() {
        _dataLoaded = false; // Reset status loading
      });
      await _loadTodayReservations(rp.currentRestaurant!.id);
      await _loadMenuCount(rp.currentRestaurant!.id);
    }
  }

  Future<void> _loadTodayReservations(String restaurantId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
          .get();

      // Juga hitung reservasi yang scheduled untuk hari ini
      final scheduledQuery = await FirebaseFirestore.instance
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('date', isEqualTo: _formatDate(now))
          .get();

      // Gabungkan hasil (hindari duplikat berdasarkan ID)
      final allReservations = <String, dynamic>{};
      querySnapshot.docs.forEach((doc) {
        allReservations[doc.id] = doc.data();
      });
      scheduledQuery.docs.forEach((doc) {
        allReservations[doc.id] = doc.data();
      });

      setState(() {
        _todayReservationCount = allReservations.length;
      });
    } catch (e) {
      print('Error loading today reservations: $e');
    }
  }

  // Method untuk menghitung jumlah menu
  Future<void> _loadMenuCount(String restaurantId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('menus')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      setState(() {
        _menuCount = querySnapshot.docs.length;
        _dataLoaded = true; // Set data sudah di-load
      });
    } catch (e) {
      print('Error loading menu count: $e');
      _dataLoaded = true; // Tetap set true meskipun error
    }
  }

  
  // Helper untuk format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
Widget build(BuildContext context) {
  final restaurantProvider = Provider.of<RestaurantProvider>(context);
  final Restaurant? restaurant = restaurantProvider.currentRestaurant;

  // Tampilkan loading jika restaurant masih loading ATAU data statistik belum di-load
  if (restaurantProvider.isLoading || 
      (restaurant != null && _todayReservationCount == 0 && _menuCount == 0 && !_dataLoaded)) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  // Jika resto belum terdaftar ATAU status pending
  if (restaurant == null || restaurant.status == 'pending') {
    return _buildRegisterPrompt();
  }

  // Jika resto sudah terdaftar dan verified
  return _buildOwnerDashboard(context, restaurant);
}

// Hapus parameter context karena sudah ada di class
Widget _buildRegisterPrompt() {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau icon
            const Icon(
              Icons.restaurant,
              size: 80,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Kelola Resto Mu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Daftar sebagai Merchant',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Bergabunglah dengan Nyam! Makaan untuk mengelola restoran Anda secara digital',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Tombol Daftar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestaurantRegisterScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Daftarkan Resto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // TAMBAHKAN parameter context
  Widget _buildOwnerDashboard(BuildContext context, Restaurant restaurant) {
  return Scaffold(
    backgroundColor: const Color(0xFFEEEEEE),
    body: RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          // Header dengan background orange curved
          _buildHeader(context, restaurant),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Grid - dipindah ke atas
                  _buildStatsGridNew(restaurant),
                  const SizedBox(height: 16),

                  // Restaurant Info Card - DESAIN BARU
                  _buildRestaurantInfoCardNew(restaurant),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtonsNew(context),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: _buildBottomNavBar(0),
  );
}

  Widget _buildHeader(BuildContext context, Restaurant restaurant) {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/nyam_makaan.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola Resto Mu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFFE4D6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Notification Badge with FCM
                  if (userId != null)
                    StreamBuilder<int>(
                      stream: FCMService.getUnreadNotificationsCount(userId),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none,
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
                    ),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfoCardNew(Restaurant restaurant) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Name and Location
              Text(
                restaurant.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              _buildAddressSmart(restaurant.address),
              const SizedBox(height: 4),
              Text(
                restaurant.categories.isNotEmpty
                    ? restaurant.categories.join(', ')
                    : 'Tidak ada kategori',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 16),

              // Status and Rating Row
              Row(
                children: [
                  // Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(restaurant.status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusText(restaurant.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Rating
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Rating',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${restaurant.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${restaurant.totalReviews} ulasan)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Map Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RestaurantMapScreen(restaurant: restaurant),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text(
                    'Lihat Map',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status Restoran (Buka/Tutup)
              _buildRestaurantStatusToggle(restaurant),
            ],
          ),
        ),
        // Icon Edit di pojok kanan atas
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditRestaurantScreen()),
              );
            },
            icon: const Icon(Icons.edit, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryOrange,
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSmart(String address) {
    // Ambil bagian pertama alamat (biasanya jalan)
    final parts = address.split(',');
    
    if (parts.length >= 2) {
      // Ambil hanya jalan dan kecamatan
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${parts[0].trim()}, ${parts[1].trim()}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            '${parts.sublist(2).join(', ')}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      // Jika alamat pendek, tampilkan langsung
      return Text(
        address,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  // DESAIN BARU Stats Grid seperti gambar 2 - compact horizontal dalam 1 card
  Widget _buildStatsGridNew(Restaurant restaurant) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItemNew(
            'Reservasi Hari Ini',
            '$_todayReservationCount',
            Icons.event_available,
          ),
          const SizedBox(width: 8),
          _buildStatItemNew(
            'Jumlah Menu',
            '$_menuCount',
            Icons.restaurant_menu,
          ),
          const SizedBox(width: 8),
          _buildStatItemNew(
            'Jumlah Ulasan',
            '${restaurant.totalReviews}',
            Icons.reviews,
          ),
          const SizedBox(width: 8),
          _buildStatItemNew(
            'Rating',
            '${restaurant.rating.toStringAsFixed(1)}',
            Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemNew(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // DESAIN BARU Action Buttons seperti gambar 2
  Widget _buildActionButtonsNew(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kelola Menu Button (seperti yang diminta)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageMenuScreen()),
              );
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Kelola Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Grid untuk tombol lainnya
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildActionButtonNew(
              context,
              'Lihat Ulasan',
              Icons.reviews,
              AppColors.primaryOrange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewReviewsScreen()),
                );
              },
            ),
            _buildActionButtonNew(
              context,
              'Reservasi',
              Icons.event_seat,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageReservationScreen(),
                  ),
                );
              },
            ),
            _buildActionButtonNew(
              context,
              'Pembayaran',
              Icons.payment,
              Colors.green,
              () {
                final restaurantProvider = Provider.of<RestaurantProvider>(
                  context,
                  listen: false,
                );
                final restaurant = restaurantProvider.currentRestaurant;
                if (restaurant != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PaymentSettingsScreen(restaurant: restaurant),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtonNew(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0, currentIndex),
              _buildNavItem(Icons.restaurant_menu, 'Menu', 1, currentIndex),
              _buildNavItem(Icons.event_seat, 'Reservasi', 2, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
    final isSelected = index == currentIndex;
    return InkWell(
      onTap: () {
        if (index != currentIndex) {
          _onItemTapped(index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk toggle status buka/tutup
  Widget _buildRestaurantStatusToggle(Restaurant restaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Restoran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleRestaurantStatus(restaurant, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: restaurant.isOpen
                          ? Colors.green
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Buka',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: restaurant.isOpen
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleRestaurantStatus(restaurant, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !restaurant.isOpen ? Colors.red : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: !restaurant.isOpen
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                restaurant.isOpen ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: restaurant.isOpen ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                restaurant.isOpen
                    ? 'Restoran Anda sedang buka'
                    : 'Restoran Anda sedang tutup',
                style: TextStyle(
                  fontSize: 12,
                  color: restaurant.isOpen ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method untuk toggle status buka/tutup
  Future<void> _toggleRestaurantStatus(
    Restaurant restaurant,
    bool isOpen,
  ) async {
    try {
      // Update di Firestore
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .update({'isOpen': isOpen, 'updatedAt': Timestamp.now()});

      // Reload restaurant data
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final rp = Provider.of<RestaurantProvider>(context, listen: false);
      await rp.loadCurrentRestaurant(auth.user!.id);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Status Berhasil Diubah',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isOpen
                      ? 'Restoran Anda sekarang dalam status BUKA. Pelanggan dapat melihat dan melakukan reservasi.'
                      : 'Restoran Anda sekarang dalam status TUTUP. Pelanggan tidak dapat melakukan reservasi untuk saat ini.',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'OKE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return AppColors.primaryOrange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}
