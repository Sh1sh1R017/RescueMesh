import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For MVP we center on a default location, e.g., San Francisco
    // In production, we'd use the device's GPS via geolocator plugin.
    const centerPosition = LatLng(37.7749, -122.4194);

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: centerPosition,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            // Use OpenStreetMap for offline-capable tiles if cached, 
            // or we'd configure a custom TileProvider pointing to local MBTiles.
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.rescuemesh.app',
            // Note: For true offline, we should use a local FileTileProvider
            // e.g. tileProvider: FileTileProvider() pointing to downloaded tiles.
          ),
          MarkerLayer(
            markers: [
              // Dummy marker for the user's location
              Marker(
                point: centerPosition,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
              // Dummy marker for a hazard
              Marker(
                point: const LatLng(37.7800, -122.4200),
                width: 60,
                height: 60,
                child: Icon(
                  Icons.person_pin_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),
              // Dummy marker for an SOS
              Marker(
                point: const LatLng(37.7700, -122.4100),
                width: 60,
                height: 60,
                child: Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add custom map marker
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
