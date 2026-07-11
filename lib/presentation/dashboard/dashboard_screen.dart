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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusCard(meshState),
          const SizedBox(height: 24),
          _buildQuickActionCard(context),
          const SizedBox(height: 16),
          _buildFemaReportButton(context),
          const SizedBox(height: 24),
          _buildRecentAlertsHeader(),
          _buildAlertItem('Medical Emergency', '2 blocks away', AppTheme.primaryColor),
          _buildAlertItem('Water Station Open', 'Community Center', AppTheme.infoColor),
          _buildAlertItem('Road Blocked', 'Main St. & 5th Ave', AppTheme.secondaryColor),
        ],
      ),
    );
  }

  Widget _buildStatusCard(MeshState meshState) {
    bool isConnected = meshState.connectedPeersCount > 0;
    
    return Card(
      elevation: 0,
      color: isConnected ? AppTheme.safeColor.withOpacity(0.2) : AppTheme.secondaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected ? AppTheme.safeColor : AppTheme.secondaryColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
              size: 48,
              color: isConnected ? AppTheme.safeColor : AppTheme.secondaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              isConnected ? 'Mesh Network Active' : 'Searching for Peers...',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '\${meshState.connectedPeersCount} nodes connected nearby',
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 16),
            if (meshState.isScanning || meshState.isAdvertising)
              const LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondaryColor),
                backgroundColor: Colors.transparent,
              )
            else 
              const SizedBox(height: 4), // Placeholder to prevent layout jump
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
              backgroundColor: AppTheme.secondaryColor,
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
              backgroundColor: AppTheme.infoColor,
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
  
  Widget _buildAlertItem(String title, String subtitle, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.notification_important, color: color),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        trailing: const Text('2m ago', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
      ),
    );
  }
}
