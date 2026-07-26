import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/message_provider.dart';
import '../../providers/device_identity_provider.dart';
import '../../domain/models/mesh_packet.dart';
import '../../domain/services/location_service.dart';
import '../../core/constants/packet_constants.dart';
import '../../core/utils/time_utils.dart';

class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(recentMessagesProvider);

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Available Resources'),
                Tab(text: 'Needed Supplies'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildResourceList(context, ref, messagesAsync, isAvailableTab: true),
                  _buildResourceList(context, ref, messagesAsync, isAvailableTab: false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showShareResourceDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Share Resource'),
      ),
    );
  }

  Widget _buildResourceList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MeshPacket>> messagesAsync, {
    required bool isAvailableTab,
  }) {
    return messagesAsync.when(
      data: (messages) {
        final resourcePackets = messages
            .where((m) => m.type == PacketType.resource)
            .toList();

        if (resourcePackets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAvailableTab ? Icons.health_and_safety : Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAvailableTab ? 'No Shared Resources Yet' : 'No Needed Supply Requests',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAvailableTab
                        ? 'Tap "Share Resource" below to broadcast water, power, or medicine to nearby off-grid nodes.'
                        : 'Emergency requests submitted over the mesh will appear here automatically.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: resourcePackets.length,
          itemBuilder: (context, index) {
            final packet = resourcePackets[index];
            return _buildRealResourceCard(context, packet);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading resources: $err')),
    );
  }

  Widget _buildRealResourceCard(BuildContext context, MeshPacket packet) {
    final timeStr = relativeTime(packet.timestamp);
    IconData icon = Icons.medical_services;
    Color iconColor = Colors.green;

    if (packet.payload.contains('WATER')) {
      icon = Icons.water_drop;
      iconColor = Colors.blue;
    } else if (packet.payload.contains('POWER')) {
      icon = Icons.electrical_services;
      iconColor = Colors.amber;
    } else if (packet.payload.contains('FOOD')) {
      icon = Icons.restaurant;
      iconColor = Colors.orange;
    } else if (packet.payload.contains('SHELTER')) {
      icon = Icons.cabin;
      iconColor = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(packet.payload.split('] ').last, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.wifi_tethering, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Hops: ${packet.hopCount}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareResourceDialog(BuildContext context, WidgetRef ref) {
    final resourceController = TextEditingController();
    String selectedType = 'WATER';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Share Resource'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resource Type:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'WATER', child: Text('💧 Clean Water')),
                  DropdownMenuItem(value: 'POWER', child: Text('⚡ Generator / Charging')),
                  DropdownMenuItem(value: 'FIRST_AID', child: Text('🩹 Medical / First Aid')),
                  DropdownMenuItem(value: 'FOOD', child: Text('🍲 Rations / Food')),
                  DropdownMenuItem(value: 'SHELTER', child: Text('🎪 Temporary Shelter')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resourceController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Resource Details & Location',
                  hintText: 'e.g., 50L drinking water available at community hall...',
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
                final details = resourceController.text.trim();
                if (details.isEmpty) return;

                final loc = await LocationService().getEmergencyLocationString();
                final nodeId = ref.read(deviceIdentityProvider);
                final syncEngine = ref.read(syncEngineProvider);

                final packet = MeshPacket(
                  msgId: 'resource_${DateTime.now().millisecondsSinceEpoch}',
                  originNodeId: nodeId,
                  type: PacketType.resource,
                  priority: PacketPriority.normal,
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  ttl: kDefaultTtlMs,
                  hopCount: 0,
                  payload: '[$selectedType] $details $loc',
                );

                await syncEngine.queueOutgoingPacket(packet);
                ref.invalidate(messagesRefreshProvider);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resource share queued for mesh broadcast.')),
                  );
                }
              },
              child: const Text('SHARE RESOURCE'),
            ),
          ],
        ),
      ),
    );
  }
}
