// screens/user/restaurant_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_model.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../models/promo_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../services/menu_service.dart';
import '../../services/review_service.dart';
import '../shared/restaurant_map_screen.dart';
import 'reservation_screen.dart';
import 'review_screen.dart';
import 'favorite_screen.dart';
import 'list_screen.dart';
import 'home_screen.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  final Promo? selectedPromo;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
    this.selectedPromo,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _getSafeRating(dynamic ratingValue) {
    if (ratingValue == null) return 0;
    if (ratingValue is int) return ratingValue;
    if (ratingValue is double) return ratingValue.toInt();
    if (ratingValue is String) return int.tryParse(ratingValue) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Sinkronisasi rating & review count di Firestore saat membuka detail resto
    ReviewService().updateRestaurantRating(widget.restaurant.id).catchError((
      e,
    ) {
      debugPrint('Sync rating error: $e');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _editReview(Map<String, dynamic> review) {
    // Convert review data to Review object
    final reviewToEdit = Review(
      id: review['id'],
      userId: review['userId'],
      userName: review['username'],
      userBadge: review['userBadge'],
      userReviewCount:
          review['userReviewCount'], // Perbaiki typo: userRevlewCount -> userReviewCount
      restaurantId: review['restaurantId'],
      restaurantName: review['restaurantName'],
      rating: _getSafeRating(
        review['rating'],
      ).toDouble(), // Ganti jadi _getSafeRating
      comment: review['comment'],
      diningOption: review['diningOption'],
      selectedMenus: List<Map<String, dynamic>>.from(
        review['selectedMenus'] ?? [],
      ), // Perbaiki: list -> List
      ownerReply: review['ownerReply'],
      createdAt: (review['createdAt'] as Timestamp).toDate(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          restaurant: widget.restaurant,
          existingReview: reviewToEdit,
        ),
      ),
    ).then((updatedReview) {
      if (updatedReview != null) {
        // Refresh the reviews list
        setState(() {});
      }
    });
  }

  void _deleteReview(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ulasan'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus ulasan ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('reviews')
                    .doc(review['id'])
                    .delete();

                // Recalculate rating & review count di Firestore
                await ReviewService().updateRestaurantRating(
                  widget.restaurant.id,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ulasan berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pop(context); // Close dialog
                // The stream will automatically update the list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus ulasan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    image: widget.restaurant.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.restaurant.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[300],
                  ),
                  child: widget.restaurant.imageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                // PERBAIKI: Tombol favorite yang berfungsi
                Consumer<RestaurantProvider>(
                  builder: (context, restaurantProvider, child) {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final user = authProvider.user; // Ambil dari AuthProvider
                    final isFavorite =
                        user != null &&
                        restaurantProvider.isFavorite(widget.restaurant.id);

                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: () {
                        if (user != null) {
                          restaurantProvider.toggleFavorite(
                            widget.restaurant.id,
                            user.id,
                          );

                          // Show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavorite
                                    ? 'Dihapus dari favorit'
                                    : 'Ditambahkan ke favorit',
                              ),
                              backgroundColor: isFavorite
                                  ? Colors.grey
                                  : Colors.green,
                            ),
                          );
                        } else {
                          // Prompt login
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Silakan login untuk menambahkan favorit',
                              ),
                              backgroundColor: AppColors.primaryOrange,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(child: _buildRestaurantInfo()),
            SliverPersistentHeader(
              delegate: _TabBarDelegate(_tabController),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildMenuTab(), _buildReviewsTab(), _buildInfoTab()],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  Widget _buildRestaurantInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.restaurant.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.restaurant.address,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.restaurant.rating > 0 &&
                  widget.restaurant.totalReviews > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    Text(
                      '${widget.restaurant.rating}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ' (${widget.restaurant.totalReviews} ratings)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              _buildRestaurantPromoBadge(),
            ],
          ),
          if (widget.restaurant.isOpen != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.restaurant.isOpen == true
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.restaurant.isOpen == true
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.restaurant.isOpen == true
                        ? Icons.access_time
                        : Icons.schedule,
                    size: 16,
                    color: widget.restaurant.isOpen == true
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.restaurant.isOpen == true
                        ? 'Buka sekarang'
                        : 'Tutup sekarang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.restaurant.isOpen == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RestaurantMapScreen(restaurant: widget.restaurant),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Lihat Map'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.restaurant.isOpen == true
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationScreen(
                                restaurant: widget.restaurant,
                                selectedPromo: widget.selectedPromo,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.event_available),
                  label: const Text('Reservasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantPromoBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promos')
          .where('restaurantId', isEqualTo: widget.restaurant.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final now = DateTime.now();
        double? bestDiscount;

        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] != true) continue;
          if (data['endDate'] == null) continue;

          final endDate = data['endDate'] is Timestamp
              ? (data['endDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['endDate']?.toString() ?? '');
          if (endDate != null && !endDate.isAfter(now)) continue;

          final discount = (data['discount'] as num?)?.toDouble();
          if (discount != null &&
              discount > 0 &&
              (bestDiscount == null || discount > bestDiscount)) {
            bestDiscount = discount;
          }
        }

        if (bestDiscount == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Diskon ${bestDiscount.toStringAsFixed(bestDiscount % 1 == 0 ? 0 : 1)}%',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuPromoBadge(Menu item) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promos')
          .where('restaurantId', isEqualTo: widget.restaurant.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final now = DateTime.now();
        double? discount;

        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] != true) continue;
          if (data['endDate'] == null) continue;

          final endDate = data['endDate'] is Timestamp
              ? (data['endDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['endDate']?.toString() ?? '');
          if (endDate != null && !endDate.isAfter(now)) continue;

          final menuIds = data['menuItems'] is List
              ? List<String>.from(
                  (data['menuItems'] as List).map((e) => e.toString()),
                )
              : <String>[];

          if (menuIds.isNotEmpty && !menuIds.contains(item.id)) continue;

          final promoDiscount = (data['discount'] as num?)?.toDouble();
          if (promoDiscount != null &&
              promoDiscount > 0 &&
              (discount == null || promoDiscount > discount)) {
            discount = promoDiscount;
          }
        }

        final percentage = discount ?? item.discountPercentage;
        if (percentage <= 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '-${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%',
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuRating(Menu item) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('restaurantId', isEqualTo: widget.restaurant.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            '${item.rating.toStringAsFixed(1)} (${item.reviewCount})',
            style: const TextStyle(fontSize: 12),
          );
        }

        double total = 0;
        int count = 0;
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final selectedMenus = data['selectedMenus'];
          if (selectedMenus is! List) continue;

          final menuNames = selectedMenus.map((selectedMenu) {
            if (selectedMenu is Map) {
              return selectedMenu['name']?.toString();
            }
            return selectedMenu.toString();
          }).whereType<String>();

          if (menuNames.any(
            (name) => name.trim().toLowerCase() ==
                item.name.trim().toLowerCase(),
          )) {
            total += (data['rating'] as num?)?.toDouble() ?? 0;
            count++;
          }
        }

        final rating = count == 0 ? item.rating : total / count;
        return Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: const TextStyle(fontSize: 12),
        );
      },
    );
  }

  // 🔥 Menu Tab (pakai MenuService)
  Widget _buildMenuTab() {
    final restaurantId = widget.restaurant.id;
    final menuService = MenuService();

    return FutureBuilder<List<Menu>>(
      future: menuService.getMenusByRestaurantId(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada menu tersedia.'));
        }

        final menus = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final item = menus[index];
            final menuImageUrl = item.mainImage;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Gambar Menu
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      image: menuImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(menuImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: menuImageUrl == null
                        ? const Icon(Icons.fastfood, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.primaryOrange,
                              size: 14,
                            ),
                            _buildMenuRating(item),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.hasDiscount)
                              Text(
                                'Rp ${item.originalPrice?.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              'Rp ${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                            if (item.hasDiscount)
                              _buildMenuPromoBadge(item),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReviewScreen(restaurant: widget.restaurant),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Tambahkan Ulasan'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('restaurantId', isEqualTo: widget.restaurant.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Firestore Error: ${snapshot.error}');
                // Fallback: tampilkan pesan error yang user-friendly
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey, size: 50),
                      SizedBox(height: 10),
                      Text(
                        'Gagal memuat ulasan',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Coba lagi nanti',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.reviews, color: Colors.grey, size: 50),
                      SizedBox(height: 10),
                      Text(
                        'Belum ada ulasan',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Jadilah yang pertama memberikan ulasan!',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              // Convert QueryDocumentSnapshot list into a List<Map<String, dynamic>>
              // and include the document id so actions (edit/delete) can use it.
              final reviews = snapshot.data!.docs.map((d) {
                final map = d.data() as Map<String, dynamic>;
                // Ensure we don't modify the original map returned by the snapshot
                return {'id': d.id, ...map};
              }).toList();

              // Sort in-memory by createdAt (descending). Handle missing/null timestamps.
              reviews.sort((a, b) {
                final aTs = a['createdAt'] is Timestamp
                    ? (a['createdAt'] as Timestamp)
                    : null;
                final bTs = b['createdAt'] is Timestamp
                    ? (b['createdAt'] as Timestamp)
                    : null;

                if (aTs == null && bTs == null) return 0;
                if (aTs == null) return 1; // push nulls to the end
                if (bTs == null) return -1;

                final aDate = aTs.toDate();
                final bDate = bTs.toDate();
                return bDate.compareTo(aDate); // Descending
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _buildReviewItem(review);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    // Format tanggal
    String formatDate(Timestamp timestamp) {
      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());

      if (difference.inDays == 0) return 'Hari ini';
      if (difference.inDays == 1) return '1 hari yang lalu';
      if (difference.inDays < 7) return '${difference.inDays} hari yang lalu';
      if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} minggu yang lalu';
      }
      return '${(difference.inDays / 30).floor()} bulan yang lalu';
    }

    // Safe rating conversion
    int getSafeRating(dynamic ratingValue) {
      if (ratingValue == null) return 0;
      if (ratingValue is int) return ratingValue;
      if (ratingValue is double) return ratingValue.toInt();
      if (ratingValue is String) return int.tryParse(ratingValue) ?? 0;
      return 0;
    }

    // Safe selected menus handling
    List<dynamic> getSafeSelectedMenus(dynamic menusValue) {
      if (menusValue is List) return menusValue;
      return [];
    }

    final rating = _getSafeRating(review['rating']);
    final selectedMenus = getSafeSelectedMenus(review['selectedMenus']);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isCurrentUserReview = review['userId'] == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan avatar, username, dan action menu
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.lightOrange,
                child: Text(
                  (review['username'] as String? ?? 'A')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['username'] as String? ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${review['userBadge'] ?? 'User'} • ${review['userReviewCount'] ?? 0} Ulasan',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isCurrentUserReview)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editReview(review);
                    } else if (value == 'delete') {
                      _deleteReview(review);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Rating dan Menu
          Row(
            children: [
              // Rating stars
              ...List.generate(5, (starIndex) {
                return Icon(
                  starIndex < rating ? Icons.star : Icons.star_border,
                  color: AppColors.primaryOrange,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              // Menu yang dipilih
              if (selectedMenus.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    selectedMenus
                        .map((menu) {
                          if (menu is String) return menu;
                          if (menu is Map) {
                            return menu['name']?.toString() ?? '';
                          }
                          return menu.toString();
                        })
                        .join(', '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Comment
          Text(
            review['comment'] as String? ?? '',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 12),

          // Footer dengan tanggal
          Row(
            children: [
              Text(
                review['createdAt'] != null
                    ? formatDate(review['createdAt'] as Timestamp)
                    : 'Baru saja',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              // Tampilkan dining option
              if (review['diningOption'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    review['diningOption'].toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem(
            'Alamat',
            widget.restaurant.address,
            Icons.location_on,
          ),
          _buildInfoItem('Telepon', widget.restaurant.phone, Icons.phone),
          if (widget.restaurant.openTime.isNotEmpty ||
              widget.restaurant.closeTime.isNotEmpty)
            _buildInfoItem(
              'Jam Buka',
              [
                widget.restaurant.openTime,
                widget.restaurant.closeTime,
              ].where((time) => time.isNotEmpty).join(' - '),
              Icons.access_time,
            ),
          _buildInfoItem(
            'Kategori',
            widget.restaurant.category,
            Icons.category,
          ),
          const SizedBox(height: 16),
          if (widget.restaurant.description.isNotEmpty) ...[
            const Text(
              'Deskripsi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.restaurant.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
    return CustomBottomNavBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            // Kembali ke home dengan pop semua screen
            Navigator.of(context).popUntil((route) => route.isFirst);
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

  // Close of _RestaurantDetailScreenState
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _TabBarDelegate(this.tabController);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primaryOrange,
        tabs: const [
          Tab(text: 'Menu'),
          Tab(text: 'Ulasan'),
          Tab(text: 'Info'),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
