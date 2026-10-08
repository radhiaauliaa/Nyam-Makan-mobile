// services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }

  // Calculate distance between two coordinates in kilometers
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  // Check if location is within radius
  bool isWithinRadius(
    double userLat, 
    double userLng, 
    double targetLat, 
    double targetLng, 
    double radiusKm
  ) {
    double distance = calculateDistance(userLat, userLng, targetLat, targetLng);
    return distance <= radiusKm;
  }

  // Get formatted address from coordinates (you'd integrate with Google Maps Geocoding API)
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // This is a placeholder - in real app you'd use Google Maps Geocoding API
    return 'Location: $lat, $lng';
  }
}