// widgets/review_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/review_model.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showRestaurantInfo;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;

  const ReviewCard({
    super.key,
    required this.review,
    this.showRestaurantInfo = false,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info and Rating
            _buildUserInfo(),

            const SizedBox(height: 12),

            // Restaurant Info (if needed)
            if (showRestaurantInfo) _buildRestaurantInfo(),

            // Review Content
            _buildReviewContent(),

            const SizedBox(height: 12),

            // Owner Reply (if exists)
            if (review.ownerReply != null) _buildOwnerReply(),

            // Actions (if needed)
            if (showActions) _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Avatar
        CircleAvatar(
          backgroundColor: AppColors.lightOrange,
          child: Text(
            review.userName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // User Details and Rating
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Name and Badge
              Row(
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (review.userBadge.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        review.userBadge,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 2),

              // User Stats
              Text(
                '${review.userReviewCount} Ulasan',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 4),

              // Rating and Menu
              Row(
                children: [
                  RatingBar.builder(
                    initialRating: review.rating.toDouble(),
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 16,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: AppColors.primaryOrange),
                    ignoreGestures: true,
                    onRatingUpdate: (rating) {},
                  ),

                  const SizedBox(width: 8),

                  if (review.selectedMenu.isNotEmpty)
                    Text(
                      review.selectedMenu,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                  const SizedBox(width: 8),

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
            ],
          ),
        ),

        // Date
        Text(
          Helpers.formatDate(review.createdAt, format: 'dd/MM/yy'),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRestaurantInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              review.restaurantName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(review.comment, style: const TextStyle(fontSize: 14, height: 1.4)),

        const SizedBox(height: 8),

        // Selected Menus
        if (review.selectedMenus.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: review.selectedMenus.map((menu) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${menu['name']} (${menu['quantity']}x)',
                  style: const TextStyle(
                    color: AppColors.darkOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildOwnerReply() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balasan Pemilik:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            review.ownerReply!,
            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Edit', style: TextStyle(fontSize: 12)),
          ),

        if (onDelete != null)
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),

        if (onReply != null && review.ownerReply == null)
          TextButton(
            onPressed: onReply,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Balas',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
      ],
    );
  }
}
