import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _collections = [
    'menus',
    'restaurants',
    'promos',
    'reviews',
    'reservations',
  ];

  static const _contextFields = {
    'menus': [
      'restaurantId',
      'name',
      'description',
      'price',
      'originalPrice',
      'category',
      'isPopular',
      'rating',
      'reviewCount',
      'isAvailable',
      'tags',
    ],
    'restaurants': [
      'name',
      'address',
      'category',
      'categories',
      'rating',
      'totalReviews',
      'description',
      'openTime',
      'closeTime',
      'openingHours',
      'isOpen',
      'priceRange',
    ],
    'promos': [
      'restaurantId',
      'title',
      'description',
      'type',
      'discount',
      'minimumOrder',
      'startDate',
      'endDate',
      'isActive',
      'menuItems',
    ],
    'reviews': [
      'restaurantId',
      'restaurantName',
      'rating',
      'comment',
      'diningOption',
      'selectedMenus',
      'ownerReply',
      'createdAt',
    ],
    'reservations': [
      'restaurantName',
      'guestCount',
      'date',
      'time',
      'area',
      'status',
      'promoTitle',
      'alternativeTime',
      'rejectionReason',
      'tableGroup',
      'tableNumber',
      'createdAt',
    ],
  };

  /// Mengambil konteks publik serta reservasi milik pengguna yang sedang login.
  Future<String> getDatabaseContext(String question) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Pengguna harus login terlebih dahulu.');
    }

    try {
      final collectionContexts = await Future.wait(
        _collections.map(
          (collectionName) =>
              _getCollectionContext(collectionName, userId: userId),
        ),
      );
      return collectionContexts.join('\n\n');
    } catch (e) {
      throw Exception('Gagal mengambil konteks Firestore: $e');
    }
  }

  Future<String> _getCollectionContext(
    String collectionName, {
    required String userId,
  }) async {
    final collection = _firestore.collection(collectionName);
    Query<Map<String, dynamic>> query = collection;
    if (collectionName == 'restaurants') {
      query = query.where('status', isEqualTo: 'verified');
    } else if (collectionName == 'promos') {
      query = query.where('isActive', isEqualTo: true);
    } else if (collectionName == 'reservations') {
      query = query.where('userId', isEqualTo: userId);
    }

    final snapshot = await query.limit(100).get();
    final now = DateTime.now();
    final fields = _contextFields[collectionName]!;
    final documents = snapshot.docs
        .map((document) {
          final data = document.data();
          if (collectionName == 'promos' &&
              !_isPromoCurrentlyActive(data, now)) {
            return null;
          }
          return jsonEncode({
            'documentId': document.id,
            ..._serializeMap({
              for (final field in fields)
                if (data.containsKey(field)) field: data[field],
            }),
          });
        })
        .whereType<String>()
        .join('\n');

    return 'KOLEKSI $collectionName:\n'
        '${documents.isEmpty ? '(kosong)' : documents}';
  }

  bool _isPromoCurrentlyActive(Map<String, dynamic> data, DateTime now) {
    if (data['isActive'] != true) return false;

    final startDate = _parseDate(data['startDate']);
    final endDate = _parseDate(data['endDate']);
    return startDate != null &&
        endDate != null &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> _serializeMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _serializeValue(value)));
  }

  dynamic _serializeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is GeoPoint) {
      return {'latitude': value.latitude, 'longitude': value.longitude};
    }
    if (value is DocumentReference) {
      return value.path;
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _serializeValue(nestedValue)),
      );
    }
    if (value is Iterable) {
      return value.map(_serializeValue).toList();
    }
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    return value.toString();
  }
}
