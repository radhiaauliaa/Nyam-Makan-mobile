// models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String userBadge;
  final int userReviewCount;
  final String restaurantId;
  final String restaurantName;
  final double rating;
  final String comment;
  final String diningOption;
  final List<Map<String, dynamic>> selectedMenus;
  final String? ownerReply;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userBadge,
    required this.userReviewCount,
    required this.restaurantId,
    required this.restaurantName,
    this.rating = 0.0,
    required this.comment,
    required this.diningOption,
    required this.selectedMenus,
    this.ownerReply,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? map['reviewId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['username'] ?? map['userName'] ?? '',
      userBadge: map['userBadge'] ?? '',
      userReviewCount: (map['userReviewCount'] ?? 0) as int,
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      diningOption: map['diningOption'] ?? '',
      selectedMenus: List<Map<String, dynamic>>.from(
        map['selectedMenus'] ?? [],
      ),
      ownerReply: map['ownerReply'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': userName,
      'userBadge': userBadge,
      'userReviewCount': userReviewCount,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'rating': rating,
      'comment': comment,
      'diningOption': diningOption,
      'selectedMenus': selectedMenus,
      'ownerReply': ownerReply,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convenience getter used by UI (single-string representation)
  String get selectedMenu {
    if (selectedMenus.isEmpty) return '';
    return selectedMenus.map((m) => (m['name'] ?? '').toString()).join(', ');
  }
}

// models/reservation_model.dart
class Reservation {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantImageUrl;
  final String customerName;
  final String customerPhone;
  final int guestCount;
  final String date;
  final String time;
  final String area;
  final List<Map<String, dynamic>> menuItems;
  final double totalAmount;
  final double dpAmount;
  final String paymentMethod;
  final String? paymentProofUrl;
  final String status;
  final String? tableGroup;
  final String? tableNumber;
  final String? rejectionReason;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImageUrl,
    required this.customerName,
    required this.customerPhone,
    required this.guestCount,
    required this.date,
    required this.time,
    required this.area,
    required this.menuItems,
    required this.totalAmount,
    required this.dpAmount,
    required this.paymentMethod,
    this.paymentProofUrl,
    required this.status,
    this.tableGroup,
    this.tableNumber,
    this.rejectionReason,
    required this.createdAt,
  });
}
