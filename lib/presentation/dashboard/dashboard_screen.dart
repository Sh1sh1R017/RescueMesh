import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mesh_provider.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meshState = ref.watch(meshStateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuickActionCard(context),
          const SizedBox(height: 16),
          _buildFemaReportButton(context),
          const SizedBox(height: 24),
          _buildRecentAlertsHeader(),
          _buildAlertItem('Medical Emergency', '2 blocks away', Icons.medical_services, AppTheme.criticalColor),
          _buildAlertItem('Water Station Open', 'Community Center', Icons.water_drop, AppTheme.textPrimaryColor),
          _buildAlertItem('Road Blocked', 'Main St. & 5th Ave', Icons.warning_amber_rounded, AppTheme.textPrimaryColor),
        ],
      ),
    );
  }


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
              backgroundColor: AppTheme.surfaceColor,
              foregroundColor: Colors.white,
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
              backgroundColor: AppTheme.surfaceColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFemaReportButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Call FemaReportGenerator and show HTML report dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating ICS-213 FEMA Report...'))
        );
      },
      icon: const Icon(Icons.assignment),
      label: const Text('Generate ICS-213 Report'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
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
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildAlertItem(String title, String subtitle, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        trailing: const Text('2m ago', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
      ),
    );
  }
}
