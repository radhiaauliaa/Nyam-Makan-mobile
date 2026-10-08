// screens/user/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../providers/restaurant_provider.dart';
import '../shared/profile_screen.dart';
import 'search_screen.dart';
import 'promo_screen.dart';
import 'favorite_screen.dart';
import 'list_screen.dart';
import 'restaurant_detail_screen.dart';
import '../../widgets/restaurant_card.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/fcm_service.dart';
import '../shared/notifications_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final restaurantProvider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // Inisialisasi lokasi pengguna
      locationProvider.initializeLocation();

      // Ambil data dari Firestore
      restaurantProvider.loadRestaurants();
      restaurantProvider.loadPopularRestaurants();

      // NOTIFICATION LISTENER - TAMBAHKAN DI SINI
      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (userId != null) {
        notifProvider.listenToUnreadCount(userId);
      }

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final username = authProvider.user?.username ?? 'Guest';

    // Loading
    if (restaurantProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEEEEEE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error
    if (restaurantProvider.error != null) {
      return Scaffold(
        backgroundColor: Color(0xFFEEEEEE),
        body: Center(
          child: Text(
            'Error: ${restaurantProvider.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // Data
    final locationProvider = Provider.of<LocationProvider>(context);

    // Update restaurants dengan jarak dan waktu real
    final popularRestaurants = locationProvider
        .updateRestaurantsDistanceAndTime(
          restaurantProvider.popularRestaurants,
        );
    final allRestaurants = locationProvider.updateRestaurantsDistanceAndTime(
      restaurantProvider.restaurants,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, username),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPromoSection(context, popularRestaurants),
                    const SizedBox(height: 24),
                    _buildPopularSection(allRestaurants),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  Widget _buildHeader(BuildContext context, String username) {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
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
                child: Image.asset(
                  'assets/nyam_makaan.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi! $username',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Nyam! Makaan',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
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
          const SizedBox(height: 20),
          // Search bar dalam header
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.primaryOrange),
                  const SizedBox(width: 12),
                  const Text(
                    'Search',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    // Tidak digunakan lagi karena sudah ada di header
    return const SizedBox.shrink();
  }

  Widget _buildPromoSection(
    BuildContext context,
    List<Restaurant> popularRestaurants,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Paling Populer Nih!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoriteScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'Lihat selengkapnya',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.primaryOrange,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularRestaurants.length > 3
                ? 3
                : popularRestaurants.length,
            itemBuilder: (context, index) {
              final restaurant = popularRestaurants[index];
              return _buildPopularCard(context, restaurant);
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PromoScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Cek Promo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularCard(BuildContext context, Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RestaurantDetailScreen(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        width: 160,
        height: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                restaurant.mainImageUrl,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 90,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image, size: 30)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant.categories.isNotEmpty
                        ? restaurant.categories.first
                        : 'Restoran',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${restaurant.rating}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant.totalReviews})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSection(List<Restaurant> restaurants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temukan makanan enak!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...restaurants.map(
          (restaurant) => RestaurantCard(restaurant: restaurant),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FavoriteScreen()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ListScreen()),
            );
            break;
        }
      },
      items: [
        BottomNavItem(icon: Icons.home, label: 'Home'),
        BottomNavItem(icon: Icons.favorite, label: 'Favorite'),
        BottomNavItem(icon: Icons.list, label: 'Reservasi'),
      ],
    );
  }
}
