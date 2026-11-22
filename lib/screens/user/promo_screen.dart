// screens/user/promo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/promo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/promo_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_model.dart';
import 'home_screen.dart';
import 'favorite_screen.dart';
import 'list_screen.dart';
import 'restaurant_detail_screen.dart';
import 'search_screen.dart';
import '../shared/profile_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../utils/helpers.dart';

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
    final isMenuPromo = promo.type == 'menu';

    // Ambil menu pertama jika promo menu
    final firstMenu = (isMenuPromo && promo.menuItems.isNotEmpty)
        ? promoProvider.getMenuForPromo(promo.menuItems.first)
        : null;

    // Tentukan URL gambar:
    // 1. Gambar menu (jika promo menu dan punya foto)
    // 2. Gambar resto (jika promo resto atau menu tidak punya foto)
    final imageUrl = (firstMenu?.mainImage != null && firstMenu!.mainImage!.isNotEmpty)
        ? firstMenu.mainImage!
        : (restaurant?.mainImageUrl ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPromoDetails(context, promo, restaurant, firstMenu),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Bagian Atas: Foto di Kiri + Info Resto & Badge di Kanan ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto Menu / Resto (Mirip ShopeeFood di Gambar 2)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 95,
                        height: 95,
                        color: Colors.grey.shade100,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildImagePlaceholder(isMenuPromo),
                                    )
                                  : _buildImagePlaceholder(isMenuPromo),
                            ),
                            // Badge di sudut foto
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isMenuPromo
                                      ? AppColors.primaryOrange
                                      : Colors.deepOrange,
                                  borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  isMenuPromo ? 'Promo Menu' : 'Diskon Resto',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Restoran & Badge Promo (Mirip ShopeeFood di Gambar 2)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Nama Restoran (Jelas, Tebal, Tidak Terpotong)
                          Text(
                            restaurant?.name ?? 'Restoran',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                          // 2. Kategori Kuliner (seperti "Nasi Ayam" / "Padang" di Gambar 2)
                          Text(
                            restaurant?.category.isNotEmpty == true
                                ? restaurant!.category
                                : (restaurant?.categories.isNotEmpty == true
                                    ? restaurant!.categories.join(', ')
                                    : 'Kuliner'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // 3. Rating & Lokasi (seperti "⭐ 4.8 (872) • Padang" di Gambar 2)
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '${restaurant?.rating ?? 0.0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if ((restaurant?.totalReviews ?? 0) > 0) ...[
                                const SizedBox(width: 2),
                                Text(
                                  ' (${restaurant!.totalReviews})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Text('•',
                                  style: TextStyle(
                                      color: Colors.grey.shade400, fontSize: 12)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  restaurant?.address.isNotEmpty == true
                                      ? restaurant!.address
                                      : 'Restoran Pilihan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // 4. Tag Promo (Diskon, Min Order)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              // Diskon Tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors['background'] as Color,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: (colors['text'] as Color)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'Diskon $discountPercent%',
                                  style: TextStyle(
                                    color: colors['text'] as Color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (promo.minimumOrder != null &&
                                  promo.minimumOrder! > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'Min. ${Helpers.formatCurrency(promo.minimumOrder!)}',
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ─── Bagian Tengah: Highlight Menu Promo (Mirip ShopeeFood Deals di Gambar 2) ───
                if (isMenuPromo && firstMenu != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DEAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            firstMenu.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (firstMenu.originalPrice != null) ...[
                          Text(
                            Helpers.formatCurrency(firstMenu.originalPrice!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          Helpers.formatCurrency(firstMenu.price),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Judul & Deskripsi Promo
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (promo.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              promo.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ─── Bagian Bawah: Masa Berlaku & Tombol Aksi ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          's.d. ${DateFormat('dd MMM yyyy').format(promo.endDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _showPromoDetails(
                            context,
                            promo,
                            restaurant,
                            firstMenu,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: restaurant != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RestaurantDetailScreen(
                                        restaurant: restaurant,
                                        selectedPromo: promo,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Pakai Promo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isMenuPromo) {
    return Center(
      child: Icon(
        isMenuPromo ? Icons.restaurant_menu : Icons.storefront,
        color: Colors.grey.shade400,
        size: 36,
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
    Restaurant? restaurant, [
    Menu? menu,
  ]) {
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
            // Header handle
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

            const SizedBox(height: 20),

            // Discount Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _getPromoColors(promo.discount.toInt())['text'] as Color,
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

            const SizedBox(height: 20),

            // Promo Details
            Text(
              promo.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            if (promo.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                promo.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 16),

            // Restaurant Info
            if (restaurant != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: restaurant.mainImageUrl.isNotEmpty
                            ? Image.network(
                                restaurant.mainImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Colors.grey),
                              )
                            : const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
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
              const SizedBox(height: 16),
            ],

            // Jika promo menu dan menu ditemukan
            if (menu != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    if (menu.mainImage != null && menu.mainImage!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          menu.mainImage!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, color: AppColors.primaryOrange),
                        ),
                      )
                    else
                      const Icon(Icons.fastfood, color: AppColors.primaryOrange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Row(
                            children: [
                              if (menu.originalPrice != null) ...[
                                Text(
                                  Helpers.formatCurrency(menu.originalPrice!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                Helpers.formatCurrency(menu.price),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryOrange,
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
              const SizedBox(height: 16),
            ],

            // Ketentuan Promo
            const Text(
              'Ketentuan Promo:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _buildTermItem(
              promo.type == 'menu'
                  ? 'Diskon langsung pada menu pilihan yang masuk promo'
                  : 'Diskon dipotong dari total tagihan saat reservasi',
            ),

            if (promo.minimumOrder != null && promo.minimumOrder! > 0)
              _buildTermItem('Minimum pembelian ${Helpers.formatCurrency(promo.minimumOrder!)}'),

            _buildTermItem('Berlaku mulai ${DateFormat('dd MMM yyyy').format(promo.startDate)} hingga ${DateFormat('dd MMM yyyy').format(promo.endDate)}'),

            if (promo.note != null && promo.note!.isNotEmpty)
              _buildTermItem('Catatan: ${promo.note!}'),

            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                          _getPromoColors(promo.discount.toInt())['text'] as Color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
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
