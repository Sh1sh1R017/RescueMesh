import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mesh_provider.dart';
import '../../providers/message_provider.dart';
import '../../domain/services/fema_report_generator.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsyncValue = ref.watch(recentAlertsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(messagesRefreshProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuickActionCard(context),
            const SizedBox(height: 16),
            _buildFemaReportButton(context, ref),
            const SizedBox(height: 24),
            _buildRecentAlertsHeader(),
            alertsAsyncValue.when(
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No recent alerts found.')),
                  );
                }
                return Column(
                  children: alerts.map((packet) {
                    final color = packet.priority == 3 ? AppTheme.criticalColor : Theme.of(context).colorScheme.onSurface;
                    final icon = packet.type == 1 ? Icons.medical_services : Icons.warning_amber_rounded;
                    final typeStr = packet.type == 1 ? 'SOS' : 'Alert';
                    return _buildAlertItem(
                      typeStr,
                      packet.payload,
                      icon,
                      color,
                      packet.timestamp,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading alerts: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Open Report Hazard Dialog
            },
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('Report Hazard'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Open Share Resource Dialog
            },
            icon: const Icon(Icons.handshake),
            label: const Text('Share Resource'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFemaReportButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        final messages = await ref.read(messageRepositoryProvider).getRecentAlerts(limit: 100);
        final htmlSource = FemaReportGenerator().generateIcs213Html(messages);
        
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('FEMA ICS-213 Report')),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(htmlSource, style: const TextStyle(fontFamily: 'monospace')),
                ),
              ),
            ),
          );
        }
      },
      icon: const Icon(Icons.assignment),
      label: const Text('Generate ICS-213 Report'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
  
  Widget _buildRecentAlertsHeader() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Text(
        'Nearby Alerts',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildAlertItem(String title, String subtitle, IconData icon, Color color, int timestamp) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    final timeStr = diff.inMinutes > 60 ? '${diff.inHours}h ago' : '${diff.inMinutes}m ago';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(timeStr, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
