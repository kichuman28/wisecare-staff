import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationService {
  // Get current location with permission handling
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Calculate distance between two points in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Format distance to readable string
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Estimate travel time based on distance (very rough estimate)
  static String estimateTravelTime(double distanceInMeters) {
    // Assuming average speed of 30 km/h in urban areas
    // 30 km/h = 8.33 m/s
    final speedInMetersPerSecond = 8.33;

    final seconds = distanceInMeters / speedInMetersPerSecond;
    final minutes = seconds / 60;

    if (minutes < 1) {
      return 'Less than 1 min';
    } else if (minutes < 60) {
      return '${minutes.round()} min';
    } else {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hours';
    }
  }

  // Get URL for navigation to a specific location
  static Future<String> getNavigationUrl(
      double latitude, double longitude) async {
    if (kIsWeb) {
      // For web, return the web URL
      return getWebNavigationUrl(latitude, longitude);
    } else if (Platform.isAndroid) {
      // For Android, use the Google Maps app URL
      return 'google.navigation:q=$latitude,$longitude&mode=d';
    } else if (Platform.isIOS) {
      // For iOS, use the Apple Maps URL scheme
      return 'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d';
    } else {
      // For other platforms, use the web URL as fallback
      return getWebNavigationUrl(latitude, longitude);
    }
  }

  // Get web fallback URL for navigation to a specific location
  static String getWebNavigationUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
  }
}
