import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  /// Fetches the current location if permissions are granted.
  /// Returns a formatted string: "📍 [Lat, Lng]" or an empty string if failed.
  Future<String> getEmergencyLocationString() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return '';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return '';
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return '';
    } 

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // Don't block emergency sends for too long
      );
      
      // Return a compact string to save BLE bandwidth
      return '[LAT: \${position.latitude.toStringAsFixed(4)}, LNG: \${position.longitude.toStringAsFixed(4)}]';
    } catch (e) {
      debugPrint('Error getting location: $e');
      return '';
    }
  }
}
