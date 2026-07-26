import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/message_provider.dart';
import '../../providers/device_identity_provider.dart';
import '../../domain/models/mesh_packet.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/fema_report_generator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../core/constants/packet_constants.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsyncValue = ref.watch(recentAlertsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentAlertsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildQuickActions(context, ref),
                  const SizedBox(height: 16),
                  _buildFemaReportButton(context, ref),
                  const SizedBox(height: 24),
                  Text(
                    'Nearby Alerts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            alertsAsyncValue.when(
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'No recent alerts found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final packet = alerts[index];
                        return AlertCard(
                          key: ValueKey(packet.msgId),
                          packet: packet,
                        );
                      },
                      childCount: alerts.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error loading alerts: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Report Hazard',
            hint: 'Opens dialog to report a hazard to nearby nodes',
            child: ElevatedButton.icon(
              onPressed: () => _showReportHazardDialog(context, ref),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Report Hazard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Share Resource',
            hint: 'Opens dialog to share water, power, or supplies',
            child: ElevatedButton.icon(
              onPressed: () => _showShareResourceDialog(context, ref),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Share Resource'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showReportHazardDialog(BuildContext context, WidgetRef ref) {
    final descriptionController = TextEditingController();
    String selectedCategory = 'FIRE';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Field Hazard'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'FIRE', child: Text('🔥 Fire / Smoke')),
                  DropdownMenuItem(value: 'FLOOD', child: Text('🌊 Flood / Water')),
                  DropdownMenuItem(value: 'ROAD_BLOCK', child: Text('🚧 Road Block / Debris')),
                  DropdownMenuItem(value: 'POLICE', child: Text('👮 Heavy Police / Tear Gas')),
                  DropdownMenuItem(value: 'MEDICAL', child: Text('🚑 Medical Emergency')),
                  DropdownMenuItem(value: 'HAZMAT', child: Text('☣️ Chemical / Toxic')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Hazard Description',
                  hintText: 'e.g., Active fire near main square, road blocked...',
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
                final desc = descriptionController.text.trim();
                if (desc.isEmpty) return;

                final loc = await LocationService().getEmergencyLocationString();
                final nodeId = ref.read(deviceIdentityProvider);
                final syncEngine = ref.read(syncEngineProvider);

                final packet = MeshPacket(
                  msgId: 'hazard_${DateTime.now().millisecondsSinceEpoch}',
                  originNodeId: nodeId,
                  type: PacketType.report,
                  priority: PacketPriority.high,
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  ttl: kDefaultTtlMs,
                  hopCount: 0,
                  payload: '[$selectedCategory] $desc $loc',
                );

                await syncEngine.queueOutgoingPacket(packet);
                ref.invalidate(messagesRefreshProvider);

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hazard report queued for mesh broadcast.')),
                );
              },
              child: const Text('SUBMIT HAZARD'),
            ),
          ],
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

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resource share queued for mesh broadcast.')),
                );
              },
              child: const Text('SHARE RESOURCE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFemaReportButton(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Generate ICS-213 Report',
      hint: 'Generates FEMA Incident Command System standard report',
      child: ElevatedButton.icon(
        onPressed: () async {
          final messages = await ref.read(messageRepositoryProvider).getRecentAlerts(limit: 100);
          final markdownSource = FemaReportGenerator().generateIcs213Markdown(messages);
          final htmlSource = FemaReportGenerator().generateIcs213Html(messages);

          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (previewContext) => Scaffold(
                appBar: AppBar(
                  title: const Text('FEMA ICS-213 Report'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy Text Report',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: markdownSource));
                        if (!previewContext.mounted) return;
                        ScaffoldMessenger.of(previewContext).showSnackBar(
                          const SnackBar(content: Text('Text Report copied to clipboard.')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.code),
                      tooltip: 'Copy HTML Markup',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: htmlSource));
                        if (!previewContext.mounted) return;
                        ScaffoldMessenger.of(previewContext).showSnackBar(
                          const SnackBar(content: Text('FEMA HTML code copied to clipboard.')),
                        );
                      },
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: markdownSource,
                    selectable: true,
                  ),
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.assignment),
        label: const Text('Generate ICS-213 Report'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

/// Independent StatelessWidget for Alert items to ensure tight rebuild scoping.
class AlertCard extends StatelessWidget {
  final MeshPacket packet;

  const AlertCard({super.key, required this.packet});

  @override
  Widget build(BuildContext context) {
    final color = packet.priority == PacketPriority.critical
        ? AppTheme.criticalColor
        : Theme.of(context).colorScheme.onSurface;
    final icon = packet.type == PacketType.sos
        ? Icons.medical_services
        : Icons.warning_amber_rounded;
    final typeStr = packet.type == PacketType.sos ? 'SOS' : 'Alert';
    final timeStr = relativeTime(packet.timestamp);

    return Semantics(
      label: '$typeStr alert: ${packet.payload}, $timeStr ago',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(typeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(packet.payload, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: Text(timeStr, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
