// providers/promo_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo_model.dart';
import '../models/restaurant_model.dart';

class PromoProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Promo> _promos = [];
  Map<String, Restaurant> _restaurantCache = {};
  bool _isLoading = false;
  String? _error;

  List<Promo> get promos => _promos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all active promos from Firebase
  Future<void> loadActivePromos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('promos')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThanOrEqualTo: now.toIso8601String())
          .get();

      _promos = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Promo.fromMap(data);
      }).toList();

      // Load restaurant data for each promo
      await _loadRestaurantData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load restaurant data for promos
  Future<void> _loadRestaurantData() async {
    final restaurantIds = _promos.map((p) => p.restaurantId).toSet();

    for (final restaurantId in restaurantIds) {
      if (!_restaurantCache.containsKey(restaurantId)) {
        try {
          final doc = await _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            data['id'] = doc.id;
            _restaurantCache[restaurantId] = Restaurant.fromMap(data);
          }
        } catch (e) {
          debugPrint('Error loading restaurant $restaurantId: $e');
        }
      }
    }
  }

  // Get restaurant for a promo
  Restaurant? getRestaurantForPromo(String restaurantId) {
    return _restaurantCache[restaurantId];
  }

  // Get promos by category
  List<Promo> getPromosByCategory(String category) {
    if (category == 'Semua') return _promos;

    return _promos.where((promo) {
      final restaurant = _restaurantCache[promo.restaurantId];
      if (restaurant == null) return false;
      return restaurant.categories.contains(category);
    }).toList();
  }

  // Get promos by restaurant
  List<Promo> getPromosByRestaurant(String restaurantId) {
    return _promos.where((p) => p.restaurantId == restaurantId).toList();
  }

  // Get promo by ID
  Promo? getPromoById(String promoId) {
    try {
      return _promos.firstWhere((p) => p.id == promoId);
    } catch (e) {
      return null;
    }
  }

  // Check if promo is valid for menu items
  bool isPromoValidForMenus(Promo promo, List<String> menuIds) {
    // If promo.menuItems is empty, it applies to all menus
    if (promo.menuItems.isEmpty) return true;

    // Check if any selected menu is in the promo's menu list
    return menuIds.any((menuId) => promo.menuItems.contains(menuId));
  }

  // Calculate discount amount
  double calculateDiscount(Promo promo, double totalAmount) {
    return totalAmount * (promo.discount / 100);
  }

  // Get category counts
  Map<String, int> getCategoryCounts() {
    final Map<String, int> counts = {
      'Semua': _promos.length,
      'Food': 0,
      'Drink': 0,
      'Dessert': 0,
    };

    for (final promo in _promos) {
      final restaurant = _restaurantCache[promo.restaurantId];
      if (restaurant != null) {
        for (final category in restaurant.categories) {
          if (counts.containsKey(category)) {
            counts[category] = counts[category]! + 1;
          }
        }
      }
    }

    return counts;
  }
}
