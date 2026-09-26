import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

/// Professional Location Service
/// Handles all geolocation functionality including current location,
/// distance calculations, and address geocoding (with OpenStreetMap Nominatim fallback for Web & Mobile)
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Permission status tracking
  bool _isPermissionGranted = false;
  LocationPermission? _permission;

  /// Check if location permissions are granted
  bool get isPermissionGranted => _isPermissionGranted;

  /// Request location permissions from user
  /// Returns true if permissions are granted, false otherwise
  Future<bool> requestLocationPermission() async {
    if (_isPermissionGranted) return true;

    try {
      _permission = await Geolocator.requestPermission();
      _isPermissionGranted = _permission == LocationPermission.always ||
                           _permission == LocationPermission.whileInUse;
      
      if (!_isPermissionGranted) {
        debugPrint('❌ Location permission denied: $_permission');
      }
      
      return _isPermissionGranted;
    } catch (e) {
      debugPrint('⚠️ Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current user location
  /// Returns LatLng coordinates or null if location cannot be determined
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Ensure permissions are granted
      if (!_isPermissionGranted) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location service is disabled');
        return null;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      debugPrint('✅ Current location: ${currentLocation.latitude}, ${currentLocation.longitude}');
      
      return currentLocation;
    } catch (e) {
      debugPrint('⚠️ Error getting current location: $e');
      return null;
    }
  }

  /// Get continuous location updates stream
  /// Useful for tracking user movement during service delivery
  Stream<LatLng> getLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Update every 10 meters
    Duration timeInterval = const Duration(seconds: 5),
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: const Duration(seconds: 30),
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  /// Calculate distance between two points in kilometers
  /// Uses Haversine formula for accurate distance calculation
  double calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    final distanceInMeters = distance(start, end);
    return distanceInMeters / 1000; // Convert to kilometers
  }

  /// Calculate distance between two points in meters
  double calculateDistanceInMeters(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance(start, end);
  }

  /// Get distance in human-readable format
  /// Returns string like "2.5 km" or "500 m"
  String getFormattedDistance(LatLng start, LatLng end) {
    final distanceInMeters = calculateDistanceInMeters(start, end);
    
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  /// Convert coordinates to readable address (Reverse Geocoding)
  /// Uses native geocoding on mobile and OpenStreetMap Nominatim on web/fallback
  Future<String> getAddressFromCoordinates(LatLng location) async {
    // 1. Try native geocoding (Mobile)
    if (!kIsWeb) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = [
            if (place.street?.isNotEmpty == true) place.street,
            if (place.subLocality?.isNotEmpty == true) place.subLocality,
            if (place.locality?.isNotEmpty == true) place.locality,
            if (place.administrativeArea?.isNotEmpty == true) place.administrativeArea,
            if (place.country?.isNotEmpty == true) place.country,
          ].where((element) => element != null && element.isNotEmpty).join(', ');

          if (address.isNotEmpty) return address;
        }
      } catch (_) {}
    }

    // 2. Try OpenStreetMap Nominatim Reverse Geocoding (Works on Web & Mobile)
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'LocalServicesApp/1.0 (contact@localservices.app)'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addrDetails = data['address'];
        if (addrDetails != null && addrDetails is Map) {
          final parts = [
            addrDetails['road'],
            addrDetails['neighbourhood'] ?? addrDetails['suburb'],
            addrDetails['city'] ?? addrDetails['town'] ?? addrDetails['village'],
            addrDetails['country'],
          ].where((e) => e != null && e.toString().isNotEmpty).toList();

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        final displayName = data['display_name'];
        if (displayName != null && displayName.toString().isNotEmpty) {
          return displayName.toString();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Nominatim reverse geocoding error: $e');
    }

    // 3. Final fallback to coordinates string
    return 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
  }

  /// Convert address to coordinates (Forward Geocoding)
  /// Uses native geocoding on mobile and OpenStreetMap Nominatim on web/fallback
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    // 1. Try native geocoding (Mobile)
    if (!kIsWeb) {
      try {
        List<Location> locations = await locationFromAddress(address);
        
        if (locations.isNotEmpty) {
          final location = locations.first;
          final coordinates = LatLng(location.latitude, location.longitude);
          debugPrint('✅ Coordinates for "$address": ${coordinates.latitude}, ${coordinates.longitude}');
          return coordinates;
        }
      } catch (_) {}
    }

    // 2. Try OpenStreetMap Nominatim Search (Works on Web & Mobile)
    try {
      final encoded = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$encoded&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'LocalServicesApp/1.0 (contact@localservices.app)'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lon = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lon != null) {
            final coordinates = LatLng(lat, lon);
            debugPrint('✅ Coordinates for "$address": ${coordinates.latitude}, ${coordinates.longitude}');
            return coordinates;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Nominatim search error: $e');
    }

    debugPrint('❌ No coordinates found for address: $address');
    return null;
  }

  /// Check if a location is within a specified radius
  /// Useful for checking if provider is within service area
  bool isWithinRadius(LatLng center, LatLng point, double radiusInKm) {
    final distance = calculateDistance(center, point);
    return distance <= radiusInKm;
  }

  /// Get bounding box for a location with given radius
  /// Useful for searching providers within a radius
  BoundingBox getBoundingBox(LatLng center, double radiusInKm) {
    // Convert radius to degrees (approximate)
    // 1 degree ≈ 111 km
    final radiusInDegrees = radiusInKm / 111.0;
    
    return BoundingBox(
      center.latitude - radiusInDegrees,
      center.longitude - radiusInDegrees,
      center.latitude + radiusInDegrees,
      center.longitude + radiusInDegrees,
    );
  }

  /// Calculate bearing between two points
  /// Returns direction in degrees (0-360)
  double calculateBearing(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.bearing(start, end);
  }

  /// Get cardinal direction from bearing
  /// Returns string like "N", "NE", "E", etc.
  String getCardinalDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing / 45) + 0.5).floor() % 8;
    return directions[index];
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open device location settings
  /// Useful when location service is disabled
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app location settings
  /// Useful when permission is permanently denied
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Helper class for bounding box calculations
class BoundingBox {
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  BoundingBox(this.minLat, this.minLng, this.maxLat, this.maxLng);

  /// Check if a point is within the bounding box
  bool contains(LatLng point) {
    return point.latitude >= minLat &&
           point.latitude <= maxLat &&
           point.longitude >= minLng &&
           point.longitude <= maxLng;
  }
}
