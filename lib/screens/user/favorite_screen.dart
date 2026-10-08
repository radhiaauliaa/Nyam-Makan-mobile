// screens/user/favorite_screen.dart
import 'package:flutter/material.dart';
import 'package:nyam_makaaan2/screens/user/home_screen.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/user_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/restaurant_card.dart';
import 'list_screen.dart';
import 'search_screen.dart';
import '../shared/profile_screen.dart';
import '../auth/login_screen.dart';
import 'reservation_detail_screen.dart';
import 'restaurant_detail_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _locationInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locationInitialized) {
      _locationInitialized = true;
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      locationProvider.initializeLocation();
    }
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantProvider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final user = authProvider.user; // Ambil user dari AuthProvider

      // Load ALL restaurants untuk hot topics dengan sorting by rating
      restaurantProvider.loadRestaurants();

      // Load favorites HANYA jika user login
      if (user != null) {
        print('User logged in, loading favorites for: ${user.id}');
        restaurantProvider.loadFavoriteRestaurants(user.id);
      } else {
        print('No user logged in, skipping favorites load');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final user = authProvider.user; // Ambil user dari AuthProvider

    // DEBUG: Check user status
    print('Current user in FavoriteScreen: ${user?.id}');
    print('Username: ${user?.username}');
    print('User object: $user');

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, user),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHotTopicsSection(
                      restaurantProvider,
                      locationProvider,
                    ), // PERBAIKI: tambahkan parameter
                    const SizedBox(height: 24),
                    _buildFavoriteRestaurants(
                      restaurantProvider,
                      locationProvider,
                      user,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 1),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    final username = user?.username ?? 'Guest';
    final isLoggedIn = user != null;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.only(
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
                    Text(
                      isLoggedIn ? 'Nyam! Makaan' : 'Login untuk akses favorit',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  _navigateToProfileScreen(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar dalam header
          GestureDetector(
            onTap: () => _navigateToSearchScreen(context),
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
    // Tidak digunakan lagi
    return const SizedBox.shrink();
  }

  // Navigation methods
  void _navigateToSearchScreen(BuildContext context) {
    print('🔍 Navigating to SearchScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchScreen()),
    );
  }

  void _navigateToProfileScreen(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.user != null;

    if (isLoggedIn) {
      print('👤 Navigating to ProfileScreen');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    } else {
      // Jika belum login, arahkan ke login screen atau show dialog
      _showLoginPrompt(context);
    }
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Diperlukan'),
        content: const Text('Silakan login untuk mengakses profil Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );

    // Sementara show message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigasi ke login screen'),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }

  Widget _buildHotTopicsSection(
    RestaurantProvider restaurantProvider,
    LocationProvider locationProvider,
  ) {
    // Get top 10 restaurants with rating > 3, sorted by rating
    final topRestaurants =
        restaurantProvider.restaurants.where((r) => r.rating > 3.0).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));

    final top10 = locationProvider.updateRestaurantsDistanceAndTime(
      topRestaurants.take(10).toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lagi Hot Topic Nih!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Lagi populer minggu ini',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        if (restaurantProvider.isLoading)
          _buildHotTopicsLoading()
        else if (top10.isEmpty)
          _buildEmptyHotTopics()
        else
          _buildHotTopicsRankingList(top10),
      ],
    );
  }

  Widget _buildHotTopicsLoading() {
    return const SizedBox(
      height: 100,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyHotTopics() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          'Belum ada restoran dengan rating tinggi',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildHotTopicsRankingList(List<Restaurant> topRestaurants) {
    return Column(
      children: topRestaurants.asMap().entries.map((entry) {
        final index = entry.key;
        final restaurant = entry.value;
        return _buildHotTopicRankingCard(context, restaurant, index + 1);
      }).toList(),
    );
  }

  Widget _buildHotTopicRankingCard(
    BuildContext context,
    Restaurant restaurant,
    int rank,
  ) {
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ranking Number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3 ? AppColors.primaryOrange : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Restaurant Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                restaurant.mainImageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Restaurant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.categories.isNotEmpty
                        ? restaurant.categories.first
                        : 'Restoran',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.primaryOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${restaurant.totalReviews})',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteRestaurants(
    RestaurantProvider restaurantProvider,
    LocationProvider locationProvider,
    UserModel? user,
  ) {
    final isLoggedIn = user != null;
    final restaurants = locationProvider.updateRestaurantsDistanceAndTime(
      restaurantProvider.favoriteRestaurants,
    ); // Ambil langsung dari provider dan update dengan jarak real

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resto Favorit Kamu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (!isLoggedIn)
            _buildLoginPrompt()
          else if (restaurantProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (restaurants.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await restaurantProvider.loadFavoriteRestaurants(user.id);
                },
                child: ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return RestaurantCard(restaurant: restaurant);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget untuk prompt login
  Widget _buildLoginPrompt() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Login Diperlukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan login untuk melihat\nrestoran favorit Anda',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login Sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Belum ada resto favorit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan resto ke favorit dengan\nmenekan ikon hati di detail resto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            break;
          case 1:
            // Already on favorite
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
