import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/packet_constants.dart';
import '../../data/mesh/cached_tile_provider.dart';
import '../../providers/message_provider.dart';
import '../../domain/models/mesh_packet.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  static final RegExp _locationRegExp =
      RegExp(r'\[LAT: ([-\d.]+), LNG: ([-\d.]+)\]');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const centerPosition = LatLng(37.7749, -122.4194);
    final messagesAsync = ref.watch(recentMessagesProvider);

    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: centerPosition,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.rescuemesh.app',
            tileProvider: CachedTileProvider(),
          ),
          messagesAsync.when(
            data: (messages) {
              final markers = <Marker>[
                // Default user location marker
                const Marker(
                  point: centerPosition,
                  width: 60,
                  height: 60,
                  child: Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 36,
                  ),
                ),
              ];

              for (final packet in messages) {
                final match = _locationRegExp.firstMatch(packet.payload);
                if (match != null) {
                  final lat = double.tryParse(match.group(1) ?? '');
                  final lng = double.tryParse(match.group(2) ?? '');
                  if (lat != null && lng != null) {
                    final latLng = LatLng(lat, lng);

                    // Choose icon and color based on message type/priority
                    IconData iconData;
                    Color markerColor;

                    if (packet.type == PacketType.sos) {
                      iconData = Icons.warning;
                      markerColor = AppTheme.criticalColor;
                    } else if (packet.type == PacketType.report) {
                      iconData = Icons.report_problem;
                      markerColor = Colors.orange;
                    } else if (packet.type == PacketType.resource) {
                      iconData = Icons.water_drop;
                      markerColor = Colors.green;
                    } else {
                      iconData = Icons.info;
                      markerColor = Colors.blueGrey;
                    }

                    markers.add(
                      Marker(
                        point: latLng,
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () {
                            _showMarkerDetails(context, packet);
                          },
                          child: Icon(
                            iconData,
                            color: markerColor,
                            size: 36,
                          ),
                        ),
                      ),
                    );
                  }
                }
              }

              return MarkerLayer(markers: markers);
            },
            loading: () => const MarkerLayer(markers: []),
            error: (_, __) => const MarkerLayer(markers: []),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Long-press map or use POST/SOS to submit location reports.')),
          );
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  void _showMarkerDetails(BuildContext context, MeshPacket packet) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final date = DateTime.fromMillisecondsSinceEpoch(packet.timestamp);
        final isSos = packet.type == PacketType.sos;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: [
              Icon(
                isSos ? Icons.warning : Icons.info,
                color: isSos ? AppTheme.criticalColor : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isSos ? 'CRITICAL SOS' : 'MAP REPORT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSos ? AppTheme.criticalColor : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Node ID: ${packet.originNodeId.substring(0, min(packet.originNodeId.length, 6))}...'),
              const SizedBox(height: 8),
              Text('Time: ${date.toLocal().toString().split('.')[0]}'),
              const SizedBox(height: 12),
              const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(packet.payload),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }
}
