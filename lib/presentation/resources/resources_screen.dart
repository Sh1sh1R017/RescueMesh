import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/message_provider.dart';
import '../../providers/device_identity_provider.dart';
import '../../domain/models/mesh_packet.dart';
import '../../domain/services/location_service.dart';
import '../../core/constants/packet_constants.dart';

class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  static const _availableResources = [
    (
      title: 'Fresh Water',
      desc: '100L available. Bring your own containers.',
      dist: '0.5 km',
      icon: Icons.water_drop,
    ),
    (
      title: 'Generator Power',
      desc: 'Running until 8PM. Charge phones/radios.',
      dist: '1.2 km',
      icon: Icons.electrical_services,
    ),
    (
      title: 'First Aid Kits',
      desc: 'Basic supplies, bandages, antiseptics.',
      dist: '3.0 km',
      icon: Icons.medical_services,
    ),
  ];

  static const _neededResources = [
    (
      title: 'Baby Formula',
      desc: 'Need formula for 6 month old.',
      priority: 'High',
    ),
    (
      title: 'Insulin',
      desc: 'Type 1 Diabetic requires immediate insulin.',
      priority: 'Critical',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Available'),
                Tab(text: 'Needed'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAvailableList(),
                  _buildNeededList(context),
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

  Widget _buildAvailableList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _availableResources.length,
      itemBuilder: (context, index) {
        final item = _availableResources[index];
        return _buildResourceCard(item.title, item.desc, item.dist, item.icon);
      },
    );
  }

  Widget _buildNeededList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _neededResources.length,
      itemBuilder: (context, index) {
        final item = _neededResources[index];
        return _buildNeededCard(context, item.title, item.desc, item.priority);
      },
    );
  }

  Widget _buildResourceCard(String title, String desc, String dist, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dist, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeededCard(BuildContext context, String title, String desc, String priority) {
    final Color pColor = priority == 'Critical'
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(desc),
        trailing: Chip(
          label: Text(priority, style: TextStyle(color: pColor, fontSize: 12)),
          backgroundColor: pColor.withValues(alpha: 0.2),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
