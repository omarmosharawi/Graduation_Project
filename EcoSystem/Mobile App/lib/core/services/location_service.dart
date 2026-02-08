// =============================================================================
// LOCATION SERVICE - GPS & Distance Calculations
// =============================================================================
// Handles location permissions and distance calculations for kiosk proximity.
// =============================================================================

import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../utils/logger.dart';

/// Location Service for GPS and distance calculations
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  /// Check and request location permission
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('Location services are disabled');
      return false;
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.warning('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.warning('Location permission permanently denied');
      return false;
    }

    AppLogger.info('Location permission granted');
    return true;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, // Update every 100 meters
        ),
      );
      
      AppLogger.info('Current location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      return _currentPosition;
    } catch (e) {
      AppLogger.error('Failed to get location: $e');
      return null;
    }
  }

  /// Calculate distance between user and a kiosk (in km)
  double calculateDistance(double kioskLat, double kioskLng) {
    if (_currentPosition == null) return -1;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      kioskLat,
      kioskLng,
    ) / 1000; // Convert meters to km
  }

  /// Calculate distance between two points (in km) - static method
  static double distanceBetween(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 0) return 'Unknown';
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Listen to location changes (for real-time tracking)
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    );
  }

  /// Open app settings (if permission denied forever)
  Future<bool> openSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
