// providers/restaurant_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/restaurant_model.dart';
import '../models/menu_model.dart';
import '../services/restaurant_service.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantProvider with ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _restaurantListener;

  List<Restaurant> _restaurants = [];
  List<Restaurant> _favoriteRestaurants = [];
  List<Restaurant> _nearbyRestaurants = [];
  List<Restaurant> _popularRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  List<Restaurant> _pendingRestaurants = [];
  List<Restaurant> _verifiedRestaurants = [];
  List<Restaurant> _rejectedRestaurants = [];
  Restaurant? _currentRestaurant;
  bool _isLoading = false;
  String? _error;

  List<Restaurant> get restaurants => _restaurants;
  List<Restaurant> get favoriteRestaurants => _favoriteRestaurants;
  List<Restaurant> get nearbyRestaurants => _nearbyRestaurants;
  List<Restaurant> get popularRestaurants => _popularRestaurants;
  List<Restaurant> get filteredRestaurants => _filteredRestaurants;
  List<Restaurant> get pendingRestaurants => _pendingRestaurants;
  List<Restaurant> get verifiedRestaurants => _verifiedRestaurants;
  List<Restaurant> get rejectedRestaurants => _rejectedRestaurants;
  Restaurant? get currentRestaurant => _currentRestaurant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all restaurants
  Future<void> loadRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _restaurants = await _restaurantService.getRestaurants();
      print('Loaded ${_restaurants.length} restaurants');
      _restaurants.forEach((r) {
        print(
          'Restaurant: ${r.name}, Categories: ${r.categories}, Images: ${r.images}',
        );
      });
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading restaurants: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentRestaurant(String ownerId) async {
  _isLoading = true;
  notifyListeners();

  try {
    _currentRestaurant = await _restaurantService.getRestaurantByOwner(ownerId);
    
    // Setup realtime listener jika restaurant ditemukan
    if (_currentRestaurant != null) {
      _setupRestaurantListener(_currentRestaurant!.id);
    }
    
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}

  // Method untuk realtime updates
  void _setupRestaurantListener(String restaurantId) {
  // Cancel previous listener if exists
  _restaurantListener?.cancel();
  
  _restaurantListener = FirebaseFirestore.instance
      .collection('restaurants')
      .doc(restaurantId)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists) {
      _currentRestaurant = Restaurant.fromMap({
        ...snapshot.data()!,
        'id': snapshot.id,
      });
      notifyListeners();
    }
  });
}

@override
void dispose() {
  _restaurantListener?.cancel();
  super.dispose();
}

  // Load nearby restaurants
  Future<void> loadNearbyRestaurants(
    double lat,
    double lng,
    double radius,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      _nearbyRestaurants = await _restaurantService.getNearbyRestaurants(
        lat,
        lng,
        radius,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load popular restaurants
  Future<void> loadPopularRestaurants() async {
    _isLoading = true;
    notifyListeners();

    try {
      _popularRestaurants = await _restaurantService.getPopularRestaurants();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // // Load current restaurant for owner
  // Future<void> loadCurrentRestaurant(String ownerId) async {
  //   _isLoading = true;
  //   notifyListeners();

  //   try {
  //     _currentRestaurant = await _restaurantService.getRestaurantByOwner(
  //       ownerId,
  //     );
  //     _isLoading = false;
  //     notifyListeners();
  //   } catch (e) {
  //     _error = e.toString();
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // Search restaurants by name, description, or categories
  Future<void> searchRestaurants(String query) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      if (query.isEmpty) {
        _filteredRestaurants = [];
      } else {
        // Gunakan search method dari service
        _filteredRestaurants = await _restaurantService.searchRestaurants(
          query,
        );

        // Fallback: jika search service tidak bekerja, filter manual
        if (_filteredRestaurants.isEmpty) {
          _filteredRestaurants = _restaurants.where((restaurant) {
            final name = restaurant.name.toLowerCase();
            final description = restaurant.description.toLowerCase();
            final categories = restaurant.categories
                .map((c) => c.toLowerCase())
                .toList();

            return name.contains(query.toLowerCase()) ||
                description.contains(query.toLowerCase()) ||
                categories.any(
                  (category) => category.contains(query.toLowerCase()),
                );
          }).toList();
        }
      }

      print('Search "$query" found ${_filteredRestaurants.length} results');
    } catch (e) {
      _error = 'Failed to search restaurants: $e';
      print('Error searching restaurants: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by category
  Future<void> filterByCategory(String category) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      if (category.isEmpty) {
        _filteredRestaurants = [];
      } else {
        // Filter manual berdasarkan kategori
        _filteredRestaurants = _restaurants.where((restaurant) {
          return restaurant.categories.any(
            (cat) => cat.toLowerCase().contains(category.toLowerCase()),
          );
        }).toList();
      }

      print(
        'Category "$category" found ${_filteredRestaurants.length} results',
      );
    } catch (e) {
      _error = 'Failed to filter by category: $e';
      print('Error filtering by category: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by price range
  Future<void> filterByPriceRange(double minPrice, double maxPrice) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _filteredRestaurants = _restaurants.where((restaurant) {
        final priceRange = restaurant.priceRange ?? {'min': 0, 'max': 0};
        final restaurantMinPrice = (priceRange['min'] as num?)?.toDouble() ?? 0;
        final restaurantMaxPrice = (priceRange['max'] as num?)?.toDouble() ?? 0;

        return restaurantMinPrice >= minPrice && restaurantMaxPrice <= maxPrice;
      }).toList();

      print(
        'Price range Rp$minPrice - Rp$maxPrice found ${_filteredRestaurants.length} results',
      );
    } catch (e) {
      _error = 'Failed to filter by price range: $e';
      print('Error filtering by price range: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Combined filter (search + category + price)
  // Di dalam class RestaurantProvider
  // Di dalam class RestaurantProvider - tambahkan method ini
  Future<void> applyCombinedFilters({
    String searchQuery = '',
    String category = '',
    double maxPrice = 200000,
  }) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      List<Restaurant> results = _restaurants;

      // Apply search filter
      if (searchQuery.isNotEmpty) {
        results = results.where((restaurant) {
          final name = restaurant.name.toLowerCase();
          final description = restaurant.description.toLowerCase();
          final categories = restaurant.categories
              .map((c) => c.toLowerCase())
              .toList();

          return name.contains(searchQuery.toLowerCase()) ||
              description.contains(searchQuery.toLowerCase()) ||
              categories.any((cat) => cat.contains(searchQuery.toLowerCase()));
        }).toList();
      }

      // Apply category filter
      if (category.isNotEmpty) {
        results = results.where((restaurant) {
          return restaurant.categories.any(
            (cat) => cat.toLowerCase().contains(category.toLowerCase()),
          );
        }).toList();
      }

      // Apply price filter - TAMPILKAN RESTO YANG MIN PRICE <= BUDGET USER
      if (maxPrice < 200000) {
        results = results.where((restaurant) {
          final priceRange = restaurant.priceRange ?? {'min': 0, 'max': 0};
          final restaurantMinPrice =
              (priceRange['min'] as num?)?.toDouble() ?? 0;

          // Tampilkan resto yang harga minimalnya <= budget user
          // Jadi kalau user pilih 30rb, tampilkan resto yang harga minimal <= 30rb
          return restaurantMinPrice <= maxPrice;
        }).toList();
      }

      _filteredRestaurants = results;

      print('Combined filters found ${_filteredRestaurants.length} results');
      print('Max price filter: Rp $maxPrice');
    } catch (e) {
      _error = 'Failed to apply filters: $e';
      print('Error applying combined filters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all filters
  void clearFilters() {
    _filteredRestaurants = [];
    _error = '';
    notifyListeners();
    print('Filters cleared');
  }

  // providers/restaurant_provider.dart - PERBAIKI toggleFavorite
  Future<void> toggleFavorite(String restaurantId, String userId) async {
    try {
      print('Toggling favorite for restaurant: $restaurantId, user: $userId');

      bool isCurrentlyFavorite = _favoriteRestaurants.any(
        (r) => r.id == restaurantId,
      );

      if (isCurrentlyFavorite) {
        await _restaurantService.removeFromFavorites(userId, restaurantId);
        _favoriteRestaurants.removeWhere((r) => r.id == restaurantId);
        print('Removed restaurant $restaurantId from favorites');
      } else {
        await _restaurantService.addToFavorites(userId, restaurantId);

        // Cari restaurant dari list restaurants atau load dari service
        Restaurant? restaurantToAdd = _restaurants.firstWhere(
          (r) => r.id == restaurantId,
          orElse: () => Restaurant(
            id: restaurantId,
            name: 'Loading...',
            address: '',
            description: '',
          ),
        );

        // Jika tidak ditemukan di local, coba load dari service
        if (restaurantToAdd.name == 'Loading...') {
          final loadedRestaurant = await _restaurantService.getRestaurantById(
            restaurantId,
          );
          if (loadedRestaurant != null) {
            restaurantToAdd = loadedRestaurant;
          }
        }

        _favoriteRestaurants.add(restaurantToAdd);
        print('Added restaurant ${restaurantToAdd.name} to favorites');
      }

      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
      _error = e.toString();
      notifyListeners();

      // Show error to user
      throw Exception('Gagal mengupdate favorit: $e');
    }
  }

  // PERBAIKI: Load favorite restaurants
  // providers/restaurant_provider.dart - TAMBAHKAN debugging
  Future<void> loadFavoriteRestaurants(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('loadFavoriteRestaurants called for user: $userId');

      _favoriteRestaurants = await _restaurantService.getFavoriteRestaurants(
        userId,
      );

      print(
        'SUCCESS: Loaded ${_favoriteRestaurants.length} favorite restaurants',
      );

      // Debug detail
      for (var i = 0; i < _favoriteRestaurants.length; i++) {
        final fav = _favoriteRestaurants[i];
        print('   ${i + 1}. ${fav.name} (${fav.id})');
        print('      Images: ${fav.images}');
        print('      ImageUrl: ${fav.imageUrl}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('ERROR loading favorite restaurants: $e');
      _error = 'Gagal memuat restoran favorit: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if restaurant is favorite
  bool isFavorite(String restaurantId) {
    return _favoriteRestaurants.any(
      (restaurant) => restaurant.id == restaurantId,
    );
  }

  // Add to favorites
  Future<bool> addToFavorites(String userId, String restaurantId) async {
    try {
      await _restaurantService.addToFavorites(userId, restaurantId);
      final restaurant = _restaurants.firstWhere((r) => r.id == restaurantId);
      _favoriteRestaurants.add(restaurant);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove from favorites
  Future<bool> removeFromFavorites(String userId, String restaurantId) async {
    try {
      await _restaurantService.removeFromFavorites(userId, restaurantId);
      _favoriteRestaurants.removeWhere((r) => r.id == restaurantId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Create new restaurant (for owner)
  Future<bool> createRestaurant(Restaurant restaurant) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Creating restaurant with link images...');
      print('Restaurant images: ${restaurant.images}');
      print('License URL: ${restaurant.license}');

      await _restaurantService.createRestaurant(restaurant);
      _currentRestaurant = restaurant;

      // SEND NOTIFICATION to all admins
      print('🔔 Calling notifyAdminsNewRestaurant...');
      await _notificationService.notifyAdminsNewRestaurant(
        restaurant.name,
        restaurant.id,
      );
      print('🔔 notifyAdminsNewRestaurant completed!');

      print('Restaurant created successfully!');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating restaurant: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update restaurant (for owner)
  Future<bool> updateRestaurant(Restaurant restaurant) async {
    try {
      await _restaurantService.updateRestaurant(restaurant);
      _currentRestaurant = restaurant;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get restaurant by ID
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      return await _restaurantService.getRestaurantById(id);
    } catch (e) {
      _error = 'Failed to get restaurant: $e';
      notifyListeners();
      return null;
    }
  }

  // providers/restaurant_provider.dart - tambahkan method ini
  Future<bool> registerRestaurant({
    required String name,
    required String address,
    required String phone,
    required String openTime,
    required String closeTime,
    required String description,
    required List<String> categories,
    required double minPrice,
    required double maxPrice,
    required List<String> imageUrls, // Sekarang menggunakan URL
    required String licenseUrl, // Sekarang menggunakan URL
    required String ownerId,
    required GeoPoint location,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Registering restaurant with image links...');
      print('Image URLs: $imageUrls');
      print('License URL: $licenseUrl');

      final restaurant = Restaurant(
        id: _firestore.collection('restaurants').doc().id,
        name: name,
        address: address,
        phone: phone,
        openTime: openTime,
        closeTime: closeTime,
        description: description,
        categories: categories,
        priceRange: {'min': minPrice, 'max': maxPrice},
        images: imageUrls,
        license: licenseUrl,
        ownerId: ownerId,
        location: location,
        status: 'pending',
        rating: 0,
        totalReviews: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _restaurantService.createRestaurant(restaurant);
      _currentRestaurant = restaurant;

      // SEND NOTIFICATION to all admins
      await _notificationService.notifyAdminsNewRestaurant(
        restaurant.name,
        restaurant.id,
      );

      print('Restaurant registered successfully!');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error registering restaurant: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load pending restaurants
  Future<void> loadPendingRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Loading pending restaurants...');
      _pendingRestaurants = await _restaurantService.getPendingRestaurants();
      print(
        'Successfully loaded ${_pendingRestaurants.length} pending restaurants',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading pending restaurants: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load verified restaurants
  Future<void> loadVerifiedRestaurants() async {
    _isLoading = true;
    notifyListeners();

    try {
      _verifiedRestaurants = await _restaurantService.getVerifiedRestaurants();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load rejected restaurants
  Future<void> loadRejectedRestaurants() async {
    _isLoading = true;
    notifyListeners();

    try {
      _rejectedRestaurants = await _restaurantService.getRejectedRestaurants();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update restaurant status
  Future<bool> updateRestaurantStatus(
    String restaurantId,
    String status, {
    String? reason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _restaurantService.updateRestaurantStatus(
        restaurantId,
        status,
        reason: reason,
      );

      // Reload the appropriate lists
      if (status == 'verified') {
        await loadPendingRestaurants();
        await loadVerifiedRestaurants();
      } else if (status == 'rejected') {
        await loadPendingRestaurants();
        await loadRejectedRestaurants();
      } else if (status == 'pending') {
        await loadRejectedRestaurants();
        await loadPendingRestaurants();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Di restaurant_provider.dart
  Future<List<Menu>> getMenusByRestaurantId(String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('menus')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      return querySnapshot.docs.map((doc) {
        return Menu.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Error getting menus: $e');
      return [];
    }
  }
}
