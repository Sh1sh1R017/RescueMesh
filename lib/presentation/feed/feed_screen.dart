import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({Key? key}) : super(key: key);

  IconData _getIconForType(String type) {
    switch (type) {
      case 'SOS': return Icons.medical_services;
      case 'Report': return Icons.warning_amber_rounded;
      case 'Resource': return Icons.water_drop;
      default: return Icons.message;
    }
  }

  Color _getColorForType(String type) {
    if (type == 'SOS') return AppTheme.criticalColor;
    return AppTheme.textPrimaryColor;
  }

  @override
  Widget build(BuildContext context) {
    // Dummy data for the MVP
    final List<Map<String, dynamic>> feedItems = [
      {
        'type': 'SOS',
        'content': 'Need immediate medical assistance for broken leg',
        'time': 'Just now',
        'distance': '1.2 km',
      },
      {
        'type': 'Report',
        'content': 'Main street bridge is flooded and impassable',
        'time': '5 mins ago',
        'distance': '0.5 km',
      },
      {
        'type': 'Resource',
        'content': 'Community center has fresh water and charging station available',
        'time': '15 mins ago',
        'distance': '2.0 km',
      },
    ];

    return Scaffold(
      body: ListView.separated(
        itemCount: feedItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = feedItems[index];
          final type = item['type'] as String;
          final color = _getColorForType(type);
          
          return ListTile(
            leading: Icon(_getIconForType(type), color: color, size: 28),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['time'],
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 2),
                      Text(
                        item['distance'],
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            subtitle: Text(
              item['content'],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            isThreeLine: true,
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'voice_btn',
            onPressed: () {
              // TODO: Start Vosk Voice Recognition Service
            },
            child: const Icon(Icons.mic),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'post_btn',
            onPressed: () {
              // TODO: Open compose message dialog
            },
            icon: const Icon(Icons.edit),
            label: const Text('POST'),
          ),
        ],
      ),
    );
  }
}
