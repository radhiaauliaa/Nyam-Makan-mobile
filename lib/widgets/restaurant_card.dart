import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../screens/user/restaurant_detail_screen.dart';
import '../utils/theme.dart';

// widgets/restaurant_card.dart
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    // Fallback untuk data yang mungkin kosong
    final restaurantName = restaurant.name.isEmpty
        ? 'Tanpa Nama'
        : restaurant.name;
    final restaurantCategory = restaurant.category.isEmpty
        ? 'Restoran'
        : restaurant.category;
    final imageUrl = restaurant.imageUrl ?? 'https://via.placeholder.com/80';
    final rating = restaurant.rating;
    final totalReviews = restaurant.totalReviews;
    final distance = restaurant.distance;
    final estimatedTime = restaurant.estimatedTime;
    final discount = restaurant.discount;

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
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? const Icon(Icons.restaurant, color: Colors.grey, size: 30)
                    : null,
              ),
              const SizedBox(width: 12),

              // Info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      restaurantCategory,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
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
                        const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance}km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${estimatedTime}min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Diskon $discount%',
                          style: const TextStyle(
                            color: AppColors.darkOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status Buka/Tutup di pojok kanan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: restaurant.isOpen
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: restaurant.isOpen
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  restaurant.isOpen ? 'Buka' : 'Tutup',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: restaurant.isOpen ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
