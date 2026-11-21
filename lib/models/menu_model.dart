// models/menu_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Menu {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String? activePromoId;
  final String category;
  final List<String> images;
  final String? imageUrl;
  final bool isPopular;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Menu({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.activePromoId,
    required this.category,
    required this.images,
    this.imageUrl,
    this.isPopular = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Menu.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images'];
    final images = rawImages is List
        ? rawImages
              .whereType<Object>()
              .map((image) => image.toString())
              .where((image) => image.isNotEmpty)
              .toList()
        : <String>[];
    final rawImageUrl = map['imageUrl']?.toString();

    return Menu(
      id: map['id'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0) is num
          ? (map['price'] as num).toDouble()
          : double.parse((map['price'] ?? '0').toString()),
      originalPrice: map['originalPrice'] != null
          ? (map['originalPrice'] as num).toDouble()
          : null,
      activePromoId: map['activePromoId'],
      category: map['category'] ?? '',
      images: images,
      imageUrl: rawImageUrl != null && rawImageUrl.isNotEmpty
          ? rawImageUrl
          : (images.isNotEmpty ? images.first : null),
      isPopular: map['isPopular'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
                DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'activePromoId': activePromoId,
      'category': category,
      'images': images,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// True jika menu sedang dalam promo (harga coretan aktif)
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// Persentase diskon yang sedang berlaku
  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0.0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  String? get mainImage => images.isNotEmpty
      ? images.first
      : (imageUrl != null && imageUrl!.isNotEmpty ? imageUrl : null);
}
