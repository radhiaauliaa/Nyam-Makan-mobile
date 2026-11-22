import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';
import '../screens/user/restaurant_detail_screen.dart';
import '../utils/theme.dart';

// widgets/restaurant_card.dart
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final imageUrl = restaurant.mainImageUrl;
    final rating = restaurant.rating;
    final totalReviews = restaurant.totalReviews;
    final distance = restaurant.distance;
    final estimatedTime = restaurant.estimatedTime;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigasi ke halaman detail restoran
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RestaurantDetailScreen(restaurant: restaurant),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isEmpty
                    ? Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                          size: 30,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (restaurant.name.isNotEmpty)
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (restaurant.category.isNotEmpty)
                      Text(
                        restaurant.category,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    _buildPromoBadge(context),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (rating > 0 && totalReviews > 0) ...[
                          const Icon(
                            Icons.star,
                            color: AppColors.primaryOrange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$rating ($totalReviews)',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (distance >= 0) ...[
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance > 0 && distance < 1
                                ? '${(distance * 1000).round()} m'
                                : '${distance.toStringAsFixed(distance > 0 && distance < 10 ? 1 : 0)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (estimatedTime >= 0) ...[
                          const Icon(
                            Icons.access_time,
                            color: Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${estimatedTime} min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              if (restaurant.isOpen != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: restaurant.isOpen == true
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: restaurant.isOpen == true
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    restaurant.isOpen == true ? 'Buka' : 'Tutup',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: restaurant.isOpen == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBadge(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promos')
          .where('restaurantId', isEqualTo: restaurant.id)
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
          if (discount != null && discount > 0 &&
              (bestDiscount == null || discount > bestDiscount)) {
            bestDiscount = discount;
          }
        }

        if (bestDiscount == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'Diskon ${bestDiscount.toStringAsFixed(bestDiscount % 1 == 0 ? 0 : 1)}%',
              style: const TextStyle(
                color: AppColors.darkOrange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
