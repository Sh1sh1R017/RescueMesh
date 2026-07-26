import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  /// Fetches the raw Position if available and permitted.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting raw position: $e');
      return null;
    }
  }

  /// Fetches the current location if permissions are granted.
  /// Returns a formatted string: "[LAT: x, LNG: y]" or an empty string if failed.
  Future<String> getEmergencyLocationString() async {
    final pos = await getCurrentPosition();
    if (pos == null) return '';
    return '[LAT: ${pos.latitude.toStringAsFixed(4)}, LNG: ${pos.longitude.toStringAsFixed(4)}]';
  }
}
