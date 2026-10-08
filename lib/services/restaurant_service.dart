// services/restaurant_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PERBAIKI: getRestaurants dengan debugging
  Future<List<Restaurant>> getRestaurants() async {
    try {
      print('Getting restaurants from Firestore...');

      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('status', isEqualTo: 'verified')
          .get();

      print('Found ${snapshot.docs.length} restaurants');

      List<Restaurant> restaurants = [];

      for (var doc in snapshot.docs) {
        print('\n=== Processing Restaurant: ${doc.id} ===');
        try {
          Restaurant restaurant = Restaurant.fromFirestore(doc);
          restaurants.add(restaurant);
          print('Success: ${restaurant.name}');
          print('   Images: ${restaurant.images}');
          print('   Image URL: ${restaurant.imageUrl}');
        } catch (e) {
          print('Error processing restaurant ${doc.id}: $e');
        }
        print('=== End Processing ===\n');
      }

      return restaurants;
    } catch (e) {
      print('Error getting restaurants: $e');
      throw Exception('Failed to load restaurants: $e');
    }
  }

  // services/restaurant_service.dart - PERBAIKI getFavoriteRestaurants
  Future<List<Restaurant>> getFavoriteRestaurants(String userId) async {
    try {
      print('Getting favorite restaurants for user: $userId');

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('User document not found for: $userId');
        return [];
      }

      // PERBAIKI: Handle berbagai kemungkinan struktur favorites
      List<dynamic> favoriteIds = [];
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null) {
        if (userData['favorites'] is List) {
          favoriteIds = userData['favorites'];
          print('Found favorites in "favorites" field: $favoriteIds');
        } else if (userData['favoriteRestaurants'] is List) {
          favoriteIds = userData['favoriteRestaurants'];
          print('Found favorites in "favoriteRestaurants" field: $favoriteIds');
        } else {
          print('No favorites field found in user document');
          return [];
        }
      }

      if (favoriteIds.isEmpty) {
        print('No favorite restaurants found');
        return [];
      }

      // PERBAIKI: Convert ke List<String> dan filter yang valid
      final List<String> validFavoriteIds = favoriteIds
          .where((id) => id != null && id.toString().isNotEmpty)
          .map((id) => id.toString())
          .toList();

      if (validFavoriteIds.isEmpty) {
        print('No valid favorite IDs found');
        return [];
      }

      print('Valid favorite IDs: $validFavoriteIds');

      // PERBAIKI: Gunakan approach yang lebih aman - load satu per satu jika whereIn gagal
      List<Restaurant> favorites = [];

      for (String restaurantId in validFavoriteIds) {
        try {
          DocumentSnapshot restaurantDoc = await _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .get();

          if (restaurantDoc.exists) {
            Restaurant restaurant = Restaurant.fromFirestore(restaurantDoc);
            favorites.add(restaurant);
            print('Loaded favorite: ${restaurant.name} ($restaurantId)');
          } else {
            print('Favorite restaurant not found: $restaurantId');
          }
        } catch (e) {
          print('Error loading favorite restaurant $restaurantId: $e');
        }
      }

      print('✅ Successfully loaded ${favorites.length} favorite restaurants');
      return favorites;
    } catch (e) {
      print('Error getting favorite restaurants: $e');
      // Jangan throw error, return empty list saja agar app tidak crash
      return [];
    }
  }

  // PERBAIKI: getPopularRestaurants
  Future<List<Restaurant>> getPopularRestaurants() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('status', isEqualTo: 'verified')
          .orderBy('rating', descending: true)
          .limit(3)
          .get();

      List<Restaurant> popularRestaurants = [];

      for (var doc in snapshot.docs) {
        try {
          Restaurant restaurant = Restaurant.fromFirestore(doc);
          popularRestaurants.add(restaurant);
          print('Popular: ${restaurant.name} - Rating: ${restaurant.rating}');
        } catch (e) {
          print('Error processing popular restaurant ${doc.id}: $e');
        }
      }

      return popularRestaurants;
    } catch (e) {
      print('Error getPopularRestaurants: $e');
      // Return empty list instead of throwing to prevent app crash
      return [];
    }
  }

  // PERBAIKI: Add to favorites dengan error handling yang better
  Future<void> addToFavorites(String userId, String restaurantId) async {
    try {
      print('Adding restaurant $restaurantId to favorites for user $userId');

      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayUnion([restaurantId]),
      });

      print('Successfully added to favorites');
    } catch (e) {
      print('Error adding to favorites: $e');
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // PERBAIKI: Remove from favorites
  Future<void> removeFromFavorites(String userId, String restaurantId) async {
    try {
      print(
        'Removing restaurant $restaurantId from favorites for user $userId',
      );

      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayRemove([restaurantId]),
      });

      print('Successfully removed from favorites');
    } catch (e) {
      print('Error removing from favorites: $e');
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Check if restaurant is favorite
  Future<bool> isFavorite(String userId, String restaurantId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      List<dynamic> favorites = userDoc['favorites'] ?? [];
      return favorites.contains(restaurantId);
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Get nearby restaurants
  Future<List<Restaurant>> getNearbyRestaurants(
    double lat,
    double lng,
    double radius,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('status', isEqualTo: 'verified')
          .get();

      return snapshot.docs.map((doc) {
        return Restaurant.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting nearby restaurants: $e');
      throw Exception('Failed to load nearby restaurants: $e');
    }
  }

  // Get restaurant by ID
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('restaurants')
          .doc(id)
          .get();

      if (doc.exists) {
        return Restaurant.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting restaurant by ID: $e');
      throw Exception('Failed to get restaurant: $e');
    }
  }

  // Search restaurants
  Future<List<Restaurant>> searchRestaurants(
    String query, {
    String? category,
    double? maxPrice,
  }) async {
    try {
      Query queryRef = _firestore
          .collection('restaurants')
          .where('status', isEqualTo: 'verified');

      QuerySnapshot snapshot = await queryRef.get();

      List<Restaurant> allRestaurants = snapshot.docs.map((doc) {
        return Restaurant.fromFirestore(doc);
      }).toList();

      // Filter manually
      List<Restaurant> filtered = allRestaurants.where((restaurant) {
        final nameMatch = restaurant.name.toLowerCase().contains(
          query.toLowerCase(),
        );
        final descMatch = restaurant.description.toLowerCase().contains(
          query.toLowerCase(),
        );
        final categoryMatch = restaurant.categories.any(
          (cat) => cat.toLowerCase().contains(query.toLowerCase()),
        );

        return nameMatch || descMatch || categoryMatch;
      }).toList();

      return filtered;
    } catch (e) {
      print('Error searching restaurants: $e');
      throw Exception('Failed to search restaurants: $e');
    }
  }

  // Update restaurant
  Future<void> updateRestaurant(Restaurant restaurant) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurant.id)
          .update(restaurant.toMap());
    } catch (e) {
      print('Error updating restaurant: $e');
      throw Exception('Failed to update restaurant: $e');
    }
  }

  // Get pending restaurants for admin
  Future<List<Restaurant>> getPendingRestaurants() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) {
        return Restaurant.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting pending restaurants: $e');
      throw Exception('Failed to load pending restaurants: $e');
    }
  }

  // Update restaurant status (for admin)
  Future<void> updateRestaurantStatus(
    String restaurantId,
    String status, {
    String? reason,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': Timestamp.now(),
      };

      if (reason != null) {
        updateData['rejectionReason'] = reason;
      }

      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .update(updateData);
    } catch (e) {
      print('Error updating restaurant status: $e');
      throw Exception('Failed to update restaurant status: $e');
    }
  }

  // Get verified restaurants
  Future<List<Restaurant>> getVerifiedRestaurants() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('status', isEqualTo: 'verified')
          .get();

      return snapshot.docs.map((doc) {
        return Restaurant.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting verified restaurants: $e');
      throw Exception('Failed to load verified restaurants: $e');
    }
  }

  // Get rejected restaurants
  Future<List<Restaurant>> getRejectedRestaurants() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('status', isEqualTo: 'rejected')
          .get();

      return snapshot.docs.map((doc) {
        return Restaurant.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Error getting rejected restaurants: $e');
      throw Exception('Failed to load rejected restaurants: $e');
    }
  }

  // Create restaurant
  Future<void> createRestaurant(Restaurant restaurant) async {
    try {
      final String restaurantId = restaurant.id.isEmpty
          ? _firestore.collection('restaurants').doc().id
          : restaurant.id;

      final restaurantWithId = Restaurant(
        id: restaurantId,
        name: restaurant.name,
        address: restaurant.address,
        phone: restaurant.phone,
        description: restaurant.description,
        images: restaurant.images,
        openingHours: restaurant.openingHours,
        categories: restaurant.categories,
        priceRange: restaurant.priceRange,
        license: restaurant.license,
        ownerId: restaurant.ownerId,
        ownerEmail: restaurant.ownerEmail, // EMAIL PEMILIK
        owner: restaurant.owner, // NAMA PEMILIK
        location: restaurant.location,
        status: restaurant.status,
        rating: restaurant.rating,
        totalReviews: restaurant.totalReviews,
        createdAt: restaurant.createdAt,
        updatedAt: restaurant.updatedAt,
        category: restaurant.category,
        distance: restaurant.distance,
        estimatedTime: restaurant.estimatedTime,
        discount: restaurant.discount,
        openTime: restaurant.openTime,
        closeTime: restaurant.closeTime,
        accountName: restaurant.accountName, // NAMA REKENING
        accountNumber: restaurant.accountNumber, // NOMOR REKENING
        bankName: restaurant.bankName, // NAMA BANK
        qrisImageUrl: restaurant.qrisImageUrl, // QRIS IMAGE
      );

      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .set(restaurantWithId.toMap());

      print('Restaurant created successfully: $restaurantId');
      print('Images: ${restaurant.images}');
      print('License: ${restaurant.license}');
    } catch (e) {
      print('Error creating restaurant: $e');
      throw Exception('Failed to create restaurant: $e');
    }
  }

  // Get restaurant by owner
  Future<Restaurant?> getRestaurantByOwner(String ownerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('restaurants')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Restaurant.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting restaurant by owner: $e');
      throw Exception('Failed to get restaurant by owner: $e');
    }
  }
}
