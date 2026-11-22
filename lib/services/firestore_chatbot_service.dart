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
    'notifications',
    'reports',
    'suspensions',
    'reported_reviews',
  ];

  /// Mengambil seluruh dokumen dari koleksi aplikasi, kecuali `users`.
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
    final snapshot = collectionName == 'reservations'
        ? await collection.where('userId', isEqualTo: userId).get()
        : await collection.get();
    final documents = snapshot.docs
        .map((document) {
          return jsonEncode({
            'documentId': document.id,
            ..._serializeMap(document.data()),
          });
        })
        .join('\n');

    return 'KOLEKSI $collectionName:\n'
        '${documents.isEmpty ? '(kosong)' : documents}';
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
