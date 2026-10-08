// models/restaurant_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String category;
  final double rating;
  final int totalReviews;
  final double distance; // in km
  final int estimatedTime; // minutes
  final int discount;
  final String? imageUrl;
  final String phone;
  final String openTime;
  final String closeTime;
  final String description;

  // Extended fields used across app
  final String status; // pending, verified, rejected
  final List<String> images;
  final String? ownerId;
  final String? ownerEmail; // Email pemilik resto untuk notifikasi
  final String? owner; // Nama pemilik resto
  final List<String> categories;
  final Map<String, dynamic>? priceRange;
  final Map<String, dynamic>? openingHours;
  final GeoPoint? location;
  final String? license;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Payment info for reservations
  final String? accountName; // Nama pemilik rekening
  final String? accountNumber; // Nomor rekening
  final String? bankName; // Nama bank
  final String? qrisImageUrl; // URL gambar QRIS

  // Restaurant operation status
  final bool isOpen; // Status buka/tutup (true = buka, false = tutup)

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.category = '',
    this.rating = 0.0,
    this.totalReviews = 0,
    this.distance = 0.0,
    this.estimatedTime = 0,
    this.discount = 0,
    this.imageUrl,
    this.phone = '',
    this.openTime = '',
    this.closeTime = '',
    this.description = '',
    this.status = 'pending',
    this.images = const [],
    this.ownerId,
    this.ownerEmail,
    this.owner,
    this.categories = const [],
    this.priceRange,
    this.openingHours,
    this.location,
    this.license,
    this.createdAt,
    this.updatedAt,
    this.accountName,
    this.accountNumber,
    this.bankName,
    this.qrisImageUrl,
    this.isOpen = true, // Default buka
  });

  // Factory fromMap - PERBAIKI dengan handling yang lebih baik
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    // Debug: print data yang diterima
    print('🔍 Restaurant.fromMap received:');
    print('   id: ${map['id']}');
    print('   name: ${map['name']}');
    print('   images: ${map['images']}');
    print('   images type: ${map['images']?.runtimeType}');
    print('   imageUrl: ${map['imageUrl']}');

    // Handle images dengan lebih robust
    List<String> images = [];
    if (map['images'] != null) {
      if (map['images'] is List) {
        try {
          images = List<String>.from(
            map['images'].map((item) => item.toString()),
          );
          print('   ✅ Successfully parsed images: $images');
        } catch (e) {
          print('   ❌ Error parsing images: $e');
          images = [];
        }
      }
    }

    // Handle imageUrl fallback
    String? imageUrl = map['imageUrl'];
    if (imageUrl == null && images.isNotEmpty) {
      imageUrl = images.first;
      print('   🔄 Using first image from images list: $imageUrl');
    }

    // Handle categories
    List<String> categories = [];
    if (map['categories'] != null && map['categories'] is List) {
      categories = List<String>.from(map['categories']);
    } else if (map['category'] != null) {
      // Fallback untuk field category tunggal
      categories = [map['category'].toString()];
    }

    // Handle priceRange
    Map<String, dynamic>? priceRange;
    if (map['priceRange'] != null && map['priceRange'] is Map) {
      priceRange = Map<String, dynamic>.from(map['priceRange']);
    } else {
      priceRange = {'min': 25000, 'max': 75000};
    }

    // Handle openingHours
    Map<String, dynamic>? openingHours;
    if (map['openingHours'] != null && map['openingHours'] is Map) {
      openingHours = Map<String, dynamic>.from(map['openingHours']);
    } else {
      openingHours = {'open': '08:00', 'close': '22:00'};
    }

    // Extract openTime dan closeTime dari openingHours
    String openTime = map['openTime'] ?? openingHours['open'] ?? '08:00';
    String closeTime = map['closeTime'] ?? openingHours['close'] ?? '22:00';

    return Restaurant(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Tanpa Nama',
      address: map['address'] ?? '',
      category: categories.isNotEmpty
          ? categories.first
          : (map['category'] ?? ''),
      rating: (map['rating'] ?? 4.9).toDouble(),
      totalReviews: map['totalReviews'] ?? 1289,
      distance: (map['distance'] ?? 0.0).toDouble(),
      estimatedTime: map['estimatedTime'] ?? 10,
      discount: map['discount'] ?? 40,
      imageUrl: imageUrl,
      phone: map['phone'] ?? '',
      openTime: openTime,
      closeTime: closeTime,
      description: map['description'] ?? '',
      status: map['status'] ?? 'verified',
      images: images,
      ownerId: map['ownerId'],
      ownerEmail: map['ownerEmail'],
      owner: map['owner'],
      categories: categories,
      priceRange: priceRange,
      openingHours: openingHours,
      location: map['location'],
      license: map['license'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      accountName: map['accountName'],
      accountNumber: map['accountNumber'],
      bankName: map['bankName'],
      qrisImageUrl: map['qrisImageUrl'],
      isOpen: map['isOpen'] ?? true, // Default buka jika tidak ada data
    );
  }

  // Create Restaurant from Firestore DocumentSnapshot - PERBAIKI
  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> map = {};

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        map.addAll(data);
      }
    }

    map['id'] = doc.id;

    // Debug Firestore data
    print('🔥 Firestore Document Data:');
    print('   Document ID: ${doc.id}');
    print('   Data: ${doc.data()}');

    // Handle location conversion jika diperlukan
    if (map['location'] is Map) {
      final loc = map['location'] as Map<String, dynamic>;
      if (loc.containsKey('latitude') && loc.containsKey('longitude')) {
        map['location'] = GeoPoint(
          (loc['latitude'] as num).toDouble(),
          (loc['longitude'] as num).toDouble(),
        );
      }
    }

    return Restaurant.fromMap(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'category': category,
      'rating': rating,
      'totalReviews': totalReviews,
      'distance': distance,
      'estimatedTime': estimatedTime,
      'discount': discount,
      'imageUrl': imageUrl,
      'phone': phone,
      'openTime': openTime,
      'closeTime': closeTime,
      'description': description,
      'status': status,
      'images': images,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'owner': owner,
      'categories': categories,
      'priceRange': priceRange,
      'openingHours': openingHours,
      'location': location,
      'license': license,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'qrisImageUrl': qrisImageUrl,
      'isOpen': isOpen,
    };
  }

  // Helper getter untuk kompatibilitas
  String get mainImageUrl =>
      imageUrl ?? (images.isNotEmpty ? images.first : '');

  // Constructor untuk registrasi
  factory Restaurant.forRegistration({
    required String name,
    required String address,
    required String phone,
    required String description,
    required List<String> images,
    required Map<String, String> openingHours,
    required List<String> categories,
    required Map<String, double> priceRange,
    required String license,
    required String ownerId,
    required GeoPoint location,
  }) {
    return Restaurant(
      id: '',
      name: name,
      address: address,
      phone: phone,
      description: description,
      images: images,
      openingHours: openingHours,
      categories: categories,
      priceRange: priceRange,
      license: license,
      ownerId: ownerId,
      location: location,
      status: 'pending',
      rating: 0,
      totalReviews: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // Set default values untuk field lainnya
      category: categories.isNotEmpty ? categories.first : '',
      distance: 0.0,
      estimatedTime: 0,
      discount: 0,
      openTime: openingHours['open'] ?? '08:00',
      closeTime: openingHours['close'] ?? '22:00',
    );
  }

  // CopyWith method for updating fields
  Restaurant copyWith({
    String? id,
    String? name,
    String? address,
    String? category,
    double? rating,
    int? totalReviews,
    double? distance,
    int? estimatedTime,
    int? discount,
    String? imageUrl,
    String? phone,
    String? openTime,
    String? closeTime,
    String? description,
    String? status,
    List<String>? images,
    String? ownerId,
    List<String>? categories,
    Map<String, dynamic>? priceRange,
    Map<String, dynamic>? openingHours,
    GeoPoint? location,
    String? license,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? qrisImageUrl,
    bool? isOpen,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      distance: distance ?? this.distance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      discount: discount ?? this.discount,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      description: description ?? this.description,
      status: status ?? this.status,
      images: images ?? this.images,
      ownerId: ownerId ?? this.ownerId,
      categories: categories ?? this.categories,
      priceRange: priceRange ?? this.priceRange,
      openingHours: openingHours ?? this.openingHours,
      location: location ?? this.location,
      license: license ?? this.license,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      qrisImageUrl: qrisImageUrl ?? this.qrisImageUrl,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
