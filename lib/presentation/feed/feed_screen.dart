import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for the MVP
    final List<Map<String, dynamic>> feedItems = [
      {
        'type': 'SOS',
        'content': 'Need immediate medical assistance for broken leg',
        'time': 'Just now',
        'distance': '1.2 km away',
        'color': AppTheme.primaryColor
      },
      {
        'type': 'Report',
        'content': 'Main street bridge is flooded and impassable',
        'time': '5 mins ago',
        'distance': '0.5 km away',
        'color': AppTheme.secondaryColor
      },
      {
        'type': 'Resource',
        'content': 'Community center has fresh water and charging station available',
        'time': '15 mins ago',
        'distance': '2.0 km away',
        'color': AppTheme.infoColor
      },
    ];

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: feedItems.length,
        itemBuilder: (context, index) {
          final item = feedItems[index];
          return Card(
            color: AppTheme.surfaceColor,
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(item['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: item['color'].withOpacity(0.2),
                        labelStyle: TextStyle(color: item['color']),
                        side: BorderSide.none,
                      ),
                      Text(
                        item['time'],
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['content'],
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        item['distance'],
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open compose message dialog
        },
        backgroundColor: AppTheme.infoColor,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
