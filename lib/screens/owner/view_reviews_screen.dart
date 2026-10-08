// screens/owner/view_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant_model.dart';
import '../../models/review_model.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';
import '../../utils/theme.dart';

class ViewReviewsScreen extends StatefulWidget {
  const ViewReviewsScreen({super.key});

  @override
  State<ViewReviewsScreen> createState() => _ViewReviewsScreenState();
}

class _ViewReviewsScreenState extends State<ViewReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Review> _reviews = [];
  Restaurant? _restaurant;
  bool _isLoading = true;

  // Statistics
  int _totalReviews = 0;
  double _averageRating = 0.0;
  int _totalReplies = 0;

  @override
  void initState() {
    super.initState();
    _loadRestaurantAndReviews();
  }

  Future<void> _loadRestaurantAndReviews() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(
        context,
        listen: false,
      );

      // Load restaurant data
      await restaurantProvider.loadCurrentRestaurant(auth.user!.id);
      _restaurant = restaurantProvider.currentRestaurant;

      if (_restaurant != null) {
        await _loadReviews();
        await _calculateStatistics();
      }
    } catch (e) {
      print('Error loading reviews: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: _restaurant!.id)
          .orderBy('createdAt', descending: true)
          .get();

      _reviews = querySnapshot.docs.map((doc) {
        return Review.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  Future<void> _calculateStatistics() async {
    if (_reviews.isEmpty) return;

    // Total reviews
    _totalReviews = _reviews.length;

    // Average rating
    final totalRating = _reviews.fold(
      0.0,
      (sum, review) => sum + review.rating,
    );
    _averageRating = totalRating / _totalReviews;

    // Total replies
    _totalReplies = _reviews
        .where(
          (review) =>
              review.ownerReply != null && review.ownerReply!.isNotEmpty,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: Column(
        children: [
          // Header orange
          _buildHeader(context),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Info
                  _buildRestaurantInfo(),

                  const SizedBox(height: 24),

                  // Review Stats
                  _buildReviewStats(),

                  const SizedBox(height: 12),

                  // Reviews List
                  Expanded(child: _buildReviewsList()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
      decoration: const BoxDecoration(color: AppColors.primaryOrange),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ulasan Pengunjung',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: _showReviewStats,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
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
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.restaurant_menu, 'Menu', 1),
              _buildNavItem(Icons.event_seat, 'Reservasi', 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected =
        false; // Tidak ada yang selected karena ini bukan salah satu dari menu utama
    return InkWell(
      onTap: () {
        if (index == 0) {
          // Navigate to home
          Navigator.pop(context);
        } else if (index == 1) {
          // Navigate to menu screen
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/owner-menu');
        } else if (index == 2) {
          // Navigate to reservation screen
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/owner-reservations');
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

  Widget _buildRestaurantInfo() {
    if (_restaurant == null) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: _restaurant!.images.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_restaurant!.images.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _restaurant!.images.isEmpty
                ? const Icon(Icons.restaurant, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _restaurant!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.primaryOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text('${_restaurant!.rating}'),
                    const SizedBox(width: 4),
                    Text(
                      '(${_restaurant!.totalReviews} ratings)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Total Ulasan', _totalReviews.toString(), Icons.reviews),
        _buildStatItem(
          'Rating Rata-rata',
          _averageRating.toStringAsFixed(1),
          Icons.star,
        ),
        _buildStatItem('Balasan', _totalReplies.toString(), Icons.reply),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightOrange,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryOrange),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada ulasan',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        return _buildReviewCard(_reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName.substring(0, 1)
                        : 'U',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${review.userBadge} • ${review.userReviewCount} Ulasan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'report') {
                      _reportReview(review);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Laporkan'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Rating and Menu - PERBAIKAN: Gunakan selectedMenu getter
            Row(
              children: [
                RatingBar.builder(
                  initialRating: review.rating.toDouble(),
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 16,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: AppColors.primaryOrange),
                  ignoreGestures: true,
                  onRatingUpdate: (rating) {},
                ),
                const SizedBox(width: 8),
                if (review.selectedMenu.isNotEmpty) ...[
                  Text(
                    review.selectedMenu,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    review.diningOption,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Comment
            Text(review.comment, style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 8),

            // Date
            Text(
              _formatDate(review.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            // Owner Reply
            if (review.ownerReply != null && review.ownerReply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryOrange,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balasan Anda:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(review.ownerReply!),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _showReplyDialog(review);
                  },
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Balas Ulasan'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} bulan yang lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return 'Beberapa menit yang lalu';
    }
  }

  Future<void> _showReplyDialog(Review review) async {
    TextEditingController replyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Balas Ulasan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Balas ulasan dari ${review.userName}:'),
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: replyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tulis balasan Anda...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (replyController.text.isNotEmpty) {
                        try {
                          // Update review with owner reply in Firestore
                          await _firestore
                              .collection('reviews')
                              .doc(review.id)
                              .update({
                                'ownerReply': replyController.text,
                                'ownerRepliedAt': FieldValue.serverTimestamp(),
                              });

                          // SEND NOTIFICATION to user
                          final notificationService = NotificationService();
                          await notificationService.notifyReviewReply(
                            review.userId,
                            _restaurant?.name ?? 'Restoran',
                            review.id,
                          );

                          // PERBAIKAN: Reload data daripada mengubah state langsung
                          await _loadReviews();
                          await _calculateStatistics();

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Balasan berhasil dikirim'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Kirim Balasan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportReview(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Ulasan'),
        content: const Text(
          'Apakah Anda yakin ingin melaporkan ulasan ini? Laporan akan dikirim ke admin untuk ditinjau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Mark review as reported
                await _firestore.collection('reviews').doc(review.id).update({
                  'reported': true,
                  'reportedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ulasan berhasil dilaporkan ke admin'),
                    backgroundColor: AppColors.primaryOrange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
            ),
            child: const Text('Laporkan'),
          ),
        ],
      ),
    );
  }

  void _showReviewStats() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Statistik Ulasan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRatingDistribution(),
              const SizedBox(height: 16),
              _buildDiningOptionStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var review in _reviews) {
      // PERBAIKAN: Convert rating to int untuk key map
      final ratingKey = review.rating.toInt();
      ratingCounts[ratingKey] = (ratingCounts[ratingKey] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribusi Rating:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...ratingCounts.entries.map((entry) {
          final percentage = _totalReviews > 0
              ? entry.value / _totalReviews
              : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text('${entry.key} bintang'),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRatingColor(entry.key),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(percentage * 100).toInt()}%'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDiningOptionStats() {
    final dineInCount = _reviews
        .where((review) => review.diningOption == 'Dine In')
        .length;
    final takeAwayCount = _reviews
        .where((review) => review.diningOption == 'Take Away')
        .length;
    final total = _reviews.length;

    final dineInPercentage = total > 0
        ? (dineInCount / total * 100).toInt()
        : 0;
    final takeAwayPercentage = total > 0
        ? (takeAwayCount / total * 100).toInt()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferensi:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPreferenceItem(
              'Dine In',
              '$dineInPercentage%',
              Icons.restaurant,
            ),
            _buildPreferenceItem(
              'Take Away',
              '$takeAwayPercentage%',
              Icons.takeout_dining,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(String label, String percentage, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: AppColors.primaryOrange),
        const SizedBox(height: 4),
        Text(percentage),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return AppColors.primaryOrange;
      case 2:
        return AppColors.primaryOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
