// screens/admin/problematic_restaurants_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/fcm_service.dart';
import '../../utils/theme.dart';

class ProblematicRestaurantsScreen extends StatefulWidget {
  const ProblematicRestaurantsScreen({super.key});

  @override
  State<ProblematicRestaurantsScreen> createState() =>
      _ProblematicRestaurantsScreenState();
}

class _ProblematicRestaurantsScreenState
    extends State<ProblematicRestaurantsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Restoran Bermasalah'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query semua resto verified, filter rating < 2.0 di client side
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .where('status', isEqualTo: 'verified')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allRestaurants = snapshot.data?.docs ?? [];

          // Filter rating < 2.0 dan totalReviews >= 5 di client side
          final restaurants = allRestaurants.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
            final totalReviews = (data['totalReviews'] as num?)?.toInt() ?? 0;
            return rating < 2.0 && totalReviews >= 5;
          }).toList();

          if (restaurants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada resto bermasalah',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Semua resto terverifikasi memiliki rating ≥ 2.0\natau belum punya cukup ulasan (min 5)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return _buildRestaurantCard(restaurant);
            },
          );
        },
      ),
    );
  }

  Widget _buildRestaurantCard(QueryDocumentSnapshot restaurant) {
    final data = restaurant.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown Restaurant';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
    final status = data['status'] ?? 'active';
    final address = data['address'] ?? '';
    final ownerId = data['ownerId'] ?? '';
    final images = (data['images'] as List?)?.cast<String>() ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : null;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Header
            Row(
              children: [
                // Image
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
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
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.isNotEmpty)
                        Text(
                          address,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Warning Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rating Buruk: ⭐ ${rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'dari $reviewCount ulasan',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Owner Info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(ownerId)
                  .get(),
              builder: (context, ownerSnapshot) {
                if (ownerSnapshot.hasData) {
                  final ownerData =
                      ownerSnapshot.data?.data() as Map<String, dynamic>?;
                  final ownerName = ownerData?['username'] ?? 'Unknown';
                  final ownerEmail = ownerData?['email'] ?? '';

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pemilik: $ownerName',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ownerEmail,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewRestaurantDetails(restaurant.id),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Lihat Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (status != 'suspended')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _suspendRestaurant(restaurant.id, name),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Tangguhkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _activateRestaurant(restaurant.id, name),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Aktifkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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

  void _viewRestaurantDetails(String restaurantId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RestaurantReviewsScreen(restaurantId: restaurantId),
      ),
    );
  }

  void _suspendRestaurant(String restaurantId, String restaurantName) {
    showDialog(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();

        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Tangguhkan Resto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Anda yakin ingin menangguhkan resto "$restaurantName"?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Alasan Penangguhan',
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
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap isi alasan penangguhan'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final suspendedAt = DateTime.now();
                  final deletionDate = suspendedAt.add(const Duration(days: 7));

                  // Get restaurant owner ID
                  final restoDoc = await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .get();
                  final ownerId = restoDoc.data()?['ownerId'] as String?;

                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .update({
                        'status': 'suspended',
                        'suspensionReason': reason,
                        'suspendedAt': Timestamp.now(),
                        'deletionDate': Timestamp.fromDate(deletionDate),
                        'updatedAt': Timestamp.now(),
                      });

                  // Send push notification to owner
                  if (ownerId != null) {
                    await FCMService.sendRestaurantSuspendedNotification(
                      ownerId: ownerId,
                      restaurantName: restaurantName,
                      suspensionReason: reason,
                      deletionDate: DateFormat(
                        'dd/MM/yyyy',
                      ).format(deletionDate),
                      adminEmail: 'admin@nyam-makanan.com',
                    );
                  }

                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Resto ditangguhkan dan notifikasi dikirim',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menangguhkan resto: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tangguhkan'),
            ),
          ],
        );
      },
    );
  }

  void _activateRestaurant(String restaurantId, String restaurantName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Resto'),
        content: Text(
          'Anda yakin ingin mengaktifkan kembali resto "$restaurantName"?',
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
                    .collection('restaurants')
                    .doc(restaurantId)
                    .update({
                      'status': 'active',
                      'suspensionReason': FieldValue.delete(),
                      'suspendedAt': FieldValue.delete(),
                      'updatedAt': Timestamp.now(),
                    });

                Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resto berhasil diaktifkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengaktifkan resto: $e'),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      case 'pending':
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
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }
}

// Screen untuk melihat semua review resto
class RestaurantReviewsScreen extends StatelessWidget {
  final String restaurantId;

  const RestaurantReviewsScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Resto'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('restaurantId', isEqualTo: restaurantId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reviews = snapshot.data?.docs ?? [];

          if (reviews.isEmpty) {
            return const Center(child: Text('Belum ada review'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              final rating = (data['rating'] as num?)?.toDouble() ?? 0;
              final comment = data['comment'] ?? '';
              final userId = data['userId'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '⭐ $rating',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: rating <= 2.0
                                  ? Colors.red
                                  : AppColors.primaryOrange,
                            ),
                          ),
                          const Spacer(),
                          if (createdAt != null)
                            Text(
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // User info
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.hasData) {
                            final userData =
                                userSnapshot.data?.data()
                                    as Map<String, dynamic>?;
                            final username = userData?['username'] ?? 'Unknown';

                            return Text(
                              'oleh: $username',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(comment),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
