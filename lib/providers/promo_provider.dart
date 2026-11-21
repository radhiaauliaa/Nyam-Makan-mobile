// providers/promo_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo_model.dart';
import '../models/restaurant_model.dart';
import '../models/menu_model.dart';

class PromoProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── State ───────────────────────────────────────────────────────────────

  List<Promo> _promos = []; // promo aktif (untuk user/PromoScreen)
  List<Promo> _ownerPromos = []; // semua promo milik satu resto (untuk owner)
  final Map<String, Restaurant> _restaurantCache = {};
  final Map<String, Menu> _menuCache = {};
  bool _isLoading = false;
  String? _error;

  List<Promo> get promos => _promos;
  List<Promo> get ownerPromos => _ownerPromos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─── Load: User (PromoScreen) ─────────────────────────────────────────────

  /// Load semua promo aktif dari seluruh restoran (untuk PromoScreen user)
  Future<void> loadActivePromos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      // Menggunakan query sederhana agar tidak membutuhkan composite index Firestore
      final snapshot = await _firestore
          .collection('promos')
          .where('isActive', isEqualTo: true)
          .get();

      final allActive = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Promo.fromMap(data);
      }).toList();

      // Filter endDate di memori
      _promos = allActive.where((p) => p.endDate.isAfter(now) || p.endDate.isAtSameMomentAs(now)).toList();
      _promos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      await _loadRestaurantData(_promos);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Load: Owner (ManagePromoScreen) ─────────────────────────────────────

  /// Load semua promo milik satu restoran (aktif, mendatang, berakhir)
  Future<void> loadPromosByRestaurant(String restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Query sederhana per restaurantId tanpa orderBy di Firestore agar bebas index error
      final snapshot = await _firestore
          .collection('promos')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      _ownerPromos = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Promo.fromMap(data);
      }).toList();

      // Urutkan berdasarkan waktu pembuatan terbaru di memori
      _ownerPromos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Filter Owner Promos ──────────────────────────────────────────────────

  List<Promo> get activeOwnerPromos =>
      _ownerPromos.where((p) => p.isCurrentlyActive).toList();

  List<Promo> get upcomingOwnerPromos =>
      _ownerPromos.where((p) => p.isUpcoming && p.isActive).toList();

  List<Promo> get expiredOwnerPromos =>
      _ownerPromos.where((p) => p.isExpired || !p.isActive).toList();

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  /// Tambah promo baru.
  /// Untuk promo tipe 'menu': otomatis update originalPrice di tiap menu
  /// yang dipilih berdasarkan persentase diskon.
  Future<void> addPromo(Promo promo) async {
    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      // 1. Simpan dokumen promo baru
      final promoRef = _firestore.collection('promos').doc();
      batch.set(promoRef, promo.toMap());

      // 2. Jika tipe menu → update originalPrice di tiap menu yang dipilih
      if (promo.type == 'menu' && promo.menuItems.isNotEmpty) {
        await _applyMenuDiscountInBatch(
          batch: batch,
          menuIds: promo.menuItems,
          discountPercent: promo.discount,
          promoId: promoRef.id,
        );
      }

      await batch.commit();

      // Refresh daftar promo owner
      await loadPromosByRestaurant(promo.restaurantId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update promo yang sudah ada.
  /// Menangani perubahan menuItems dan diskon secara konsisten.
  Future<void> updatePromo(Promo promo) async {
    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      final promoRef = _firestore.collection('promos').doc(promo.id);
      batch.update(promoRef, {
        ...promo.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (promo.type == 'menu') {
        // Ambil data promo lama untuk tahu menu mana yang perlu di-reset
        final oldDoc = await promoRef.get();
        final oldMenuIds = oldDoc.exists
            ? List<String>.from(oldDoc.data()?['menuItems'] ?? [])
            : <String>[];

        // Reset originalPrice menu yang tidak lagi masuk promo
        final removedMenuIds =
            oldMenuIds.where((id) => !promo.menuItems.contains(id)).toList();
        await _removeMenuDiscountInBatch(
            batch: batch, menuIds: removedMenuIds);

        // Apply diskon baru ke menu yang sekarang masuk promo
        if (promo.menuItems.isNotEmpty) {
          await _applyMenuDiscountInBatch(
            batch: batch,
            menuIds: promo.menuItems,
            discountPercent: promo.discount,
            promoId: promo.id!,
          );
        }
      }

      await batch.commit();
      await loadPromosByRestaurant(promo.restaurantId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Nonaktifkan promo (soft delete — isActive = false).
  /// Untuk promo tipe 'menu': otomatis hapus originalPrice dari menu terdampak.
  Future<void> deactivatePromo(Promo promo) async {
    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();

      // 1. Set isActive = false
      final promoRef = _firestore.collection('promos').doc(promo.id);
      batch.update(promoRef, {
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 2. Jika tipe menu → hapus originalPrice dari semua menu terdampak
      if (promo.type == 'menu' && promo.menuItems.isNotEmpty) {
        await _removeMenuDiscountInBatch(
            batch: batch, menuIds: promo.menuItems);
      }

      await batch.commit();
      await loadPromosByRestaurant(promo.restaurantId);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ─── Validasi ─────────────────────────────────────────────────────────────

  /// Cek apakah menu tertentu sudah masuk ke promo aktif lain.
  /// Digunakan saat owner membuat/mengedit promo untuk mencegah satu menu
  /// masuk dua promo aktif sekaligus.
  /// [excludePromoId] diisi saat edit promo (promo dirinya sendiri tidak dihitung)
  Future<List<String>> getMenuIdsAlreadyInActivePromo(
    String restaurantId,
    List<String> menuIds, {
    String? excludePromoId,
  }) async {
    final now = DateTime.now();
    // Query sederhana agar tidak memerlukan composite index
    final snapshot = await _firestore
        .collection('promos')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    final conflictMenuIds = <String>[];

    for (final doc in snapshot.docs) {
      if (excludePromoId != null && doc.id == excludePromoId) continue;

      final data = doc.data();
      final isActive = data['isActive'] == true;
      if (!isActive) continue;

      // Cek apakah tanggal promo masih berlaku
      if (data['endDate'] != null) {
        final endDate = DateTime.tryParse(data['endDate'].toString());
        if (endDate != null && endDate.isBefore(now)) continue;
      }

      final existingMenuIds =
          List<String>.from(data['menuItems'] ?? []);
      for (final menuId in menuIds) {
        if (existingMenuIds.contains(menuId) &&
            !conflictMenuIds.contains(menuId)) {
          conflictMenuIds.add(menuId);
        }
      }
    }

    return conflictMenuIds;
  }

  // ─── Kalkulasi Diskon (untuk ReservationScreen) ───────────────────────────

  /// Validasi apakah promo restoran berlaku untuk menu yang dipilih user
  bool isPromoValidForMenus(Promo promo, List<String> menuIds) {
    if (promo.menuItems.isEmpty) return true;
    return menuIds.any((menuId) => promo.menuItems.contains(menuId));
  }

  /// Hitung nilai diskon dari total order.
  /// Jika ada minimumOrder, return 0 jika total tidak memenuhi syarat.
  double calculateDiscount(Promo promo, double totalAmount) {
    if (promo.minimumOrder != null && totalAmount < promo.minimumOrder!) {
      return 0;
    }
    return totalAmount * (promo.discount / 100);
  }

  // ─── Filter & Query (User) ────────────────────────────────────────────────

  Menu? getMenuForPromo(String menuId) {
    return _menuCache[menuId];
  }

  bool _isCategoryMatch(Restaurant restaurant, String targetCategory) {
    final catList = [
      restaurant.category.toLowerCase(),
      ...restaurant.categories.map((c) => c.toLowerCase()),
    ];

    if (targetCategory == 'Food') {
      return catList.any((c) =>
          c.contains('food') ||
          c.contains('makan') ||
          c.contains('ramen') ||
          c.contains('ayam') ||
          c.contains('nasi') ||
          c.contains('bakmi') ||
          c.contains('padang') ||
          c.contains('geprek') ||
          c.contains('pizza') ||
          c.contains('burger') ||
          c.contains('sate') ||
          c.contains('japanese') ||
          c.contains('korean') ||
          c.contains('indonesia'));
    } else if (targetCategory == 'Drink') {
      return catList.any((c) =>
          c.contains('drink') ||
          c.contains('minum') ||
          c.contains('kopi') ||
          c.contains('coffee') ||
          c.contains('tea') ||
          c.contains('teh') ||
          c.contains('boba') ||
          c.contains('matcha') ||
          c.contains('jus') ||
          c.contains('juice'));
    } else if (targetCategory == 'Dessert') {
      return catList.any((c) =>
          c.contains('dessert') ||
          c.contains('ice cream') ||
          c.contains('es krim') ||
          c.contains('cake') ||
          c.contains('kue') ||
          c.contains('donat') ||
          c.contains('sweet'));
    }
    return catList.any((c) => c.contains(targetCategory.toLowerCase()));
  }

  List<Promo> getPromosByCategory(String category) {
    if (category == 'Semua') return _promos;

    return _promos.where((promo) {
      final restaurant = _restaurantCache[promo.restaurantId];
      if (restaurant == null) return false;
      return _isCategoryMatch(restaurant, category);
    }).toList();
  }

  List<Promo> getPromosByRestaurant(String restaurantId) {
    return _promos.where((p) => p.restaurantId == restaurantId).toList();
  }

  Promo? getPromoById(String promoId) {
    try {
      return _promos.firstWhere((p) => p.id == promoId);
    } catch (e) {
      return null;
    }
  }

  Restaurant? getRestaurantForPromo(String restaurantId) {
    return _restaurantCache[restaurantId];
  }

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
        if (_isCategoryMatch(restaurant, 'Food')) {
          counts['Food'] = (counts['Food'] ?? 0) + 1;
        }
        if (_isCategoryMatch(restaurant, 'Drink')) {
          counts['Drink'] = (counts['Drink'] ?? 0) + 1;
        }
        if (_isCategoryMatch(restaurant, 'Dessert')) {
          counts['Dessert'] = (counts['Dessert'] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  // ─── Helper Internal ──────────────────────────────────────────────────────

  Future<void> _loadRestaurantData(List<Promo> promos) async {
    final restaurantIds = promos.map((p) => p.restaurantId).toSet();

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

    // Cache menu data untuk promo tipe menu
    final menuIds = promos.expand((p) => p.menuItems).toSet();
    for (final menuId in menuIds) {
      if (!_menuCache.containsKey(menuId)) {
        try {
          final doc = await _firestore.collection('menus').doc(menuId).get();
          if (doc.exists) {
            final data = doc.data()!;
            data['id'] = doc.id;
            _menuCache[menuId] = Menu.fromMap(data);
          }
        } catch (e) {
          debugPrint('Error loading menu $menuId: $e');
        }
      }
    }
  }

  /// Terapkan diskon ke dokumen menu dalam batch:
  /// - originalPrice = harga dasar sebelum promo
  /// - price = harga diskon (basePrice * (1 - discount/100))
  Future<void> _applyMenuDiscountInBatch({
    required WriteBatch batch,
    required List<String> menuIds,
    required double discountPercent,
    required String promoId,
  }) async {
    for (final menuId in menuIds) {
      final menuDoc =
          await _firestore.collection('menus').doc(menuId).get();
      if (!menuDoc.exists) continue;

      final data = menuDoc.data()!;
      // Jika menu sudah punya originalPrice (misal sedang diedit), ambil originalPrice sebagai dasar.
      // Jika baru pertama didiskon, price saat ini adalah harga dasarnya.
      final double basePrice = (data['originalPrice'] as num?)?.toDouble() ??
          (data['price'] as num?)?.toDouble() ??
          0.0;

      final discountedPrice = basePrice * (1 - discountPercent / 100);

      batch.update(_firestore.collection('menus').doc(menuId), {
        'originalPrice': basePrice,
        'price': discountedPrice,
        'activePromoId': promoId,
      });
    }
  }

  /// Hapus diskon dan kembalikan harga asli ke dokumen menu dalam batch
  Future<void> _removeMenuDiscountInBatch({
    required WriteBatch batch,
    required List<String> menuIds,
  }) async {
    for (final menuId in menuIds) {
      final menuDoc =
          await _firestore.collection('menus').doc(menuId).get();
      if (!menuDoc.exists) continue;

      final data = menuDoc.data()!;
      final originalPrice = (data['originalPrice'] as num?)?.toDouble();

      if (originalPrice != null) {
        batch.update(_firestore.collection('menus').doc(menuId), {
          'price': originalPrice,
          'originalPrice': null,
          'activePromoId': null,
        });
      } else {
        batch.update(_firestore.collection('menus').doc(menuId), {
          'activePromoId': null,
        });
      }
    }
  }
}
