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
  bool _isUsingSimulationLocation = false;

  // Lokasi simulasi untuk emulator atau perangkat yang belum memiliki GPS.
  // Dapat diganti otomatis saat GPS pengguna berhasil didapatkan.
  static const double _simulationLatitude = -0.9499;
  static const double _simulationLongitude = 100.3543;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null;
  bool get isUsingSimulationLocation => _isUsingSimulationLocation;

  // Inisialisasi dan dapatkan lokasi pengguna
  Future<void> initializeLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (!_isUsablePosition(_currentPosition)) {
        _currentPosition = _createSimulationPosition();
        _isUsingSimulationLocation = true;
        _error = null;
      } else if (!_isLikelyIndonesianPosition(_currentPosition)) {
        _currentPosition = _createSimulationPosition();
        _isUsingSimulationLocation = true;
        _error = null;
      } else {
        _isUsingSimulationLocation = false;
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      // Jika gagal, coba ambil last known position
      try {
        final lastPosition = await _locationService.getLastKnownPosition();
        if (_isUsablePosition(lastPosition)) {
          if (_isLikelyIndonesianPosition(lastPosition)) {
            _currentPosition = lastPosition;
            _isUsingSimulationLocation = false;
          } else {
            _currentPosition = _createSimulationPosition();
            _isUsingSimulationLocation = true;
          }
        } else {
          _currentPosition = _createSimulationPosition();
          _isUsingSimulationLocation = true;
        }
        _error = null;
      } catch (e) {
        _currentPosition = _createSimulationPosition();
        _isUsingSimulationLocation = true;
        _error = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isUsablePosition(Position? position) {
    if (position == null) return false;
    if (position.latitude.abs() < 0.0001 &&
        position.longitude.abs() < 0.0001) {
      return false;
    }
    return position.latitude >= -90 &&
        position.latitude <= 90 &&
        position.longitude >= -180 &&
        position.longitude <= 180;
  }

  bool _isLikelyIndonesianPosition(Position? position) {
    if (position == null) return false;
    return position.latitude >= -11.0 &&
        position.latitude <= 6.0 &&
        position.longitude >= 95.0 &&
        position.longitude <= 141.0;
  }

  Position _createSimulationPosition() {
    return Position(
      latitude: _simulationLatitude,
      longitude: _simulationLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
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
    return timeInMinutes < 1 ? 1 : timeInMinutes;
  }

  // Update jarak dan waktu untuk restaurant
  Restaurant updateRestaurantDistanceAndTime(Restaurant restaurant) {
    if (_currentPosition == null) {
      return restaurant;
    }

    var distance = calculateDistanceToRestaurant(restaurant);
    var time = estimateTravelTime(distance);

    if (_isUsingSimulationLocation) {
      distance = distance.clamp(0.0, 1140.0).toDouble();
      time = time.clamp(0, 120).toInt();
    }

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
