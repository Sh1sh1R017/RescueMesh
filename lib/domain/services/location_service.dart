import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  /// Fetches the raw Position if available and permitted.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await Geolocator.getLastKnownPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return await Geolocator.getLastKnownPosition();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 2),
      );
      return position;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting raw position, using last known: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Fetches the current location if permissions are granted.
  /// Returns a formatted string: "[LAT: x, LNG: y]" or an empty string if failed.
  Future<String> getEmergencyLocationString() async {
    try {
      final pos = await getCurrentPosition();
      if (pos == null) return '';
      return '[LAT: ${pos.latitude.toStringAsFixed(4)}, LNG: ${pos.longitude.toStringAsFixed(4)}]';
    } catch (_) {
      return '';
    }
  }
}
