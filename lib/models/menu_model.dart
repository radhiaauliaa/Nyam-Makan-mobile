// models/menu_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Menu {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
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
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
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

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0.0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  String? get mainImage => images.isNotEmpty ? images.first : null;
}
