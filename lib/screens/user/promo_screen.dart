// screens/user/promo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/promo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/promo_model.dart';
import '../../models/restaurant_model.dart';
import 'home_screen.dart';
import 'favorite_screen.dart';
import 'list_screen.dart';
import 'restaurant_detail_screen.dart';
import 'search_screen.dart';
import '../shared/profile_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  String _selectedCategory = 'Semua';
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final promoProvider = Provider.of<PromoProvider>(context, listen: false);
      promoProvider.loadActivePromos();
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            const SizedBox(height: 24),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo Categories
                    _buildPromoCategories(context),

                    const SizedBox(height: 24),

                    // Promo List
                    Expanded(child: _buildPromoList(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final username = authProvider.user?.username ?? 'Guest';

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
                    const Text(
                      'Nyam! Makaan',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
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

  Widget _buildPromoCategories(BuildContext context) {
    return Consumer<PromoProvider>(
      builder: (context, promoProvider, child) {
        final counts = promoProvider.getCategoryCounts();
        final categories = [
          {
            'name': 'Semua',
            'icon': Icons.all_inclusive,
            'count': counts['Semua'] ?? 0,
          },
          {
            'name': 'Food',
            'icon': Icons.restaurant,
            'count': counts['Food'] ?? 0,
          },
          {
            'name': 'Drink',
            'icon': Icons.local_cafe,
            'count': counts['Drink'] ?? 0,
          },
          {
            'name': 'Dessert',
            'icon': Icons.icecream,
            'count': counts['Dessert'] ?? 0,
          },
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Promo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _buildCategoryItem(category);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isSelected = _selectedCategory == category['name'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category['name'];
        });
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : AppColors.lightOrange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.lightOrange,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'] as IconData,
              color: isSelected ? Colors.white : AppColors.primaryOrange,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              category['name'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${category['count']} promo',
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoList(BuildContext context) {
    return Consumer<PromoProvider>(
      builder: (context, promoProvider, child) {
        if (promoProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (promoProvider.error != null) {
          return Center(
            child: Text(
              'Error: ${promoProvider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final promos = promoProvider.getPromosByCategory(_selectedCategory);

        if (promos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada promo tersedia',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cek Promo dulu Yuk!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: promos.length,
                itemBuilder: (context, index) {
                  return _buildPromoCard(context, promos[index], promoProvider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPromoCard(
    BuildContext context,
    Promo promo,
    PromoProvider promoProvider,
  ) {
    final restaurant = promoProvider.getRestaurantForPromo(promo.restaurantId);
    final discountPercent = promo.discount.toInt();
    final colors = _getPromoColors(discountPercent);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors['background'] as Color, Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors['text'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$discountPercent% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Promo Title
              Text(
                promo.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Promo Description
              Text(
                promo.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Restaurant and Expiry
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant?.name ?? 'Restoran',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Berlaku hingga ${DateFormat('dd MMM yyyy').format(promo.endDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showPromoDetails(context, promo, restaurant);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors['text'] as Color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Lihat Detail & Gunakan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getPromoColors(int discount) {
    if (discount >= 50) {
      return {'background': Colors.red[50]!, 'text': Colors.red};
    } else if (discount >= 30) {
      return {'background': Colors.blue[50]!, 'text': Colors.blue};
    } else if (discount >= 20) {
      return {'background': Colors.green[50]!, 'text': Colors.green};
    } else {
      return {
        'background': AppColors.lightOrange,
        'text': AppColors.primaryOrange,
      };
    }
  }

  void _showPromoDetails(
    BuildContext context,
    Promo promo,
    Restaurant? restaurant,
  ) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Discount Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      _getPromoColors(promo.discount.toInt())['text'] as Color,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'DISKON ${promo.discount.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Promo Details
            Text(
              promo.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              promo.description,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Restaurant Info
            if (restaurant != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            restaurant.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Terms and Conditions
            const Text(
              'Syarat & Ketentuan:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...promo.terms.map((term) => _buildTermItem(term)),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: restaurant != null
                        ? () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailScreen(
                                  restaurant: restaurant,
                                  selectedPromo: promo,
                                ),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _getPromoColors(promo.discount.toInt())['text']
                              as Color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Gunakan Promo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        // Handle navigation
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteScreen()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ListScreen()),
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
