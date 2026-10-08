// providers/location_provider.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/restaurant_model.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null;

  // Inisialisasi dan dapatkan lokasi pengguna
  Future<void> initializeLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      _error = null;
    } catch (e) {
      _error = e.toString();
      // Jika gagal, coba ambil last known position
      try {
        _currentPosition = await _locationService.getLastKnownPosition();
      } catch (e) {
        print('Failed to get last known position: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hitung jarak dari lokasi pengguna ke restoran (dalam km)
  double calculateDistanceToRestaurant(Restaurant restaurant) {
    if (_currentPosition == null || restaurant.location == null) {
      return 0.0;
    }

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      restaurant.location!.latitude,
      restaurant.location!.longitude,
    );
  }

  // Estimasi waktu tempuh berdasarkan jarak (dalam menit)
  // Asumsi: kecepatan rata-rata 30 km/jam di dalam kota
  int estimateTravelTime(double distanceInKm) {
    if (distanceInKm == 0.0) return 0;

    const averageSpeedKmPerHour = 30.0;
    final timeInHours = distanceInKm / averageSpeedKmPerHour;
    final timeInMinutes = (timeInHours * 60).round();

    // Minimal 5 menit, maksimal 120 menit
    return timeInMinutes.clamp(5, 120);
  }

  // Update jarak dan waktu untuk restaurant
  Restaurant updateRestaurantDistanceAndTime(Restaurant restaurant) {
    if (_currentPosition == null) {
      return restaurant;
    }

    final distance = calculateDistanceToRestaurant(restaurant);
    final time = estimateTravelTime(distance);

    // Create new restaurant dengan distance dan time yang updated
    return Restaurant(
      id: restaurant.id,
      name: restaurant.name,
      address: restaurant.address,
      category: restaurant.category,
      rating: restaurant.rating,
      totalReviews: restaurant.totalReviews,
      distance: double.parse(distance.toStringAsFixed(1)), // Round to 1 decimal
      estimatedTime: time,
      discount: restaurant.discount,
      imageUrl: restaurant.imageUrl,
      phone: restaurant.phone,
      openTime: restaurant.openTime,
      closeTime: restaurant.closeTime,
      description: restaurant.description,
      status: restaurant.status,
      images: restaurant.images,
      ownerId: restaurant.ownerId,
      categories: restaurant.categories,
      priceRange: restaurant.priceRange,
      openingHours: restaurant.openingHours,
      location: restaurant.location,
      license: restaurant.license,
      createdAt: restaurant.createdAt,
      updatedAt: restaurant.updatedAt,
      accountName: restaurant.accountName,
      accountNumber: restaurant.accountNumber,
      bankName: restaurant.bankName,
      qrisImageUrl: restaurant.qrisImageUrl,
      isOpen: restaurant.isOpen,
    );
  }

  // Update list restaurant dengan jarak dan waktu
  List<Restaurant> updateRestaurantsDistanceAndTime(
    List<Restaurant> restaurants,
  ) {
    if (_currentPosition == null) {
      return restaurants;
    }

    return restaurants.map((restaurant) {
      return updateRestaurantDistanceAndTime(restaurant);
    }).toList();
  }

  // Request permission jika belum ada
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await _locationService.requestPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Refresh location
  Future<void> refreshLocation() async {
    await initializeLocation();
  }
}
