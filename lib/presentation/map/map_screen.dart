import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/packet_constants.dart';
import '../../data/mesh/cached_tile_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/device_identity_provider.dart';
import '../../domain/models/mesh_packet.dart';
import '../../domain/services/location_service.dart';


class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static final RegExp _locationRegExp =
      RegExp(r'\[LAT: ([-\d.]+), LNG: ([-\d.]+)\]');

  int _selectedFilterType = 0; // 0=All, 1=SOS, 2=Reports/Hazards, 4=Resources
  LatLng _currentCenter = const LatLng(27.7172, 85.3240); // Initialized to default disaster response region (Kathmandu/Global)

  @override
  void initState() {
    super.initState();
    _determineCenterLocation();
  }

  Future<void> _determineCenterLocation() async {
    try {
      // 1. Attempt to center on actual live device GPS location
      final pos = await LocationService().getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _currentCenter = LatLng(pos.latitude, pos.longitude);
        });
        return;
      }

      // 2. Fallback: Center on the latest emergency report location in SQLite
      final messages = await ref.read(messageRepositoryProvider).getRecentMessages(limit: 10);
      for (final packet in messages) {
        final match = _locationRegExp.firstMatch(packet.payload);
        if (match != null) {
          final lat = double.tryParse(match.group(1) ?? '');
          final lng = double.tryParse(match.group(2) ?? '');
          if (lat != null && lng != null && mounted) {
            setState(() {
              _currentCenter = LatLng(lat, lng);
            });
            return;
          }
        }
      }
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(recentMessagesProvider);


    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14.0,
              onLongPress: (tapPosition, point) {
                _showAddCustomMarkerDialog(context, point);
              },
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
                    Marker(
                      point: _currentCenter,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 36,
                      ),
                    ),
                  ];


                  for (final packet in messages) {
                    if (_selectedFilterType != 0 && packet.type != _selectedFilterType) {
                      continue;
                    }

                    final match = _locationRegExp.firstMatch(packet.payload);
                    if (match != null) {
                      final lat = double.tryParse(match.group(1) ?? '');
                      final lng = double.tryParse(match.group(2) ?? '');
                      if (lat != null && lng != null) {
                        final latLng = LatLng(lat, lng);

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

          // Top Filter Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 0),
                  const SizedBox(width: 8),
                  _buildFilterChip('🆘 SOS', PacketType.sos),
                  const SizedBox(width: 8),
                  _buildFilterChip('⚠️ HAZARDS', PacketType.report),
                  const SizedBox(width: 8),
                  _buildFilterChip('💧 RESOURCES', PacketType.resource),
                ],
              ),
            ),
          ),

          // Offline Status Indicator
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.secondary),
              ),
              child: const Row(
                children: [
                  Icon(Icons.offline_pin, size: 14, color: Colors.green),
                  SizedBox(width: 6),
                  Text('OFFLINE MAP CACHE ACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Long-press anywhere on the map to pin a hazard or resource.')),
          );
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  Widget _buildFilterChip(String label, int type) {
    final bool isSelected = _selectedFilterType == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: Theme.of(context).colorScheme.primary,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilterType = type;
          });
        }
      },
    );
  }

  void _showAddCustomMarkerDialog(BuildContext context, LatLng point) {
    final textController = TextEditingController();
    int selectedType = PacketType.report;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pin Map Emergency Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: [LAT: ${point.latitude.toStringAsFixed(4)}, LNG: ${point.longitude.toStringAsFixed(4)}]'),
              const SizedBox(height: 12),
              DropdownButton<int>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: PacketType.report, child: Text('⚠️ Hazard Report')),
                  DropdownMenuItem(value: PacketType.resource, child: Text('💧 Shared Resource')),
                  DropdownMenuItem(value: PacketType.sos, child: Text('🆘 Emergency SOS')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Report Details',
                  hintText: 'Describe situation at this pinned point...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                final details = textController.text.trim();
                if (details.isEmpty) return;

                final loc = '[LAT: ${point.latitude.toStringAsFixed(6)}, LNG: ${point.longitude.toStringAsFixed(6)}]';
                final nodeId = ref.read(deviceIdentityProvider);
                final syncEngine = ref.read(syncEngineProvider);

                final packet = MeshPacket(
                  msgId: 'pin_${DateTime.now().millisecondsSinceEpoch}',
                  originNodeId: nodeId,
                  type: selectedType,
                  priority: selectedType == PacketType.sos ? PacketPriority.critical : PacketPriority.high,
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  ttl: kDefaultTtlMs,
                  hopCount: 0,
                  payload: '$details $loc',
                );

                await syncEngine.queueOutgoingPacket(packet);
                ref.invalidate(messagesRefreshProvider);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pinned location report queued for mesh broadcast.')),
                  );
                }
              },
              child: const Text('PIN & BROADCAST'),
            ),
          ],
        ),
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
