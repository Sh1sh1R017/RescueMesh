import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/message_provider.dart';
import '../../providers/device_identity_provider.dart';
import '../../domain/models/mesh_packet.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({Key? key}) : super(key: key);

  IconData _getIconForType(int type) {
    switch (type) {
      case 1: return Icons.medical_services;
      case 2: return Icons.warning_amber_rounded;
      case 4: return Icons.water_drop;
      default: return Icons.message;
    }
  }

  Color _getColorForType(int type) {
    if (type == 1) return AppTheme.criticalColor;
    return AppTheme.textPrimaryColor;
  }

  String _getTypeString(int type) {
    switch (type) {
      case 1: return 'SOS';
      case 2: return 'Report';
      case 3: return 'Missing';
      case 4: return 'Resource';
      default: return 'Chat';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsyncValue = ref.watch(recentMessagesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(messagesRefreshProvider);
        },
        child: messagesAsyncValue.when(
          data: (messages) {
            if (messages.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No messages in feed yet.')),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: messages.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final packet = messages[index];
                final color = _getColorForType(packet.type);
                final typeStr = _getTypeString(packet.type);
                
                final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(packet.timestamp));
                final timeStr = diff.inMinutes > 60 ? '${diff.inHours}h ago' : '${diff.inMinutes}m ago';

                return ListTile(
                  leading: Icon(_getIconForType(packet.type), color: color, size: 28),
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          typeStr.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondaryColor),
                            const SizedBox(width: 2),
                            Text(
                              'Near', // Location placeholder for MVP
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  subtitle: Text(
                    packet.payload,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  isThreeLine: true,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading feed: $err')),
        ),
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
            onPressed: () => _showComposeDialog(context, ref),
            icon: const Icon(Icons.edit),
            label: const Text('POST'),
          ),
        ],
      ),
    );
  }

  void _showComposeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your message...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              
              final syncEngine = ref.read(syncEngineProvider);
              final nodeId = ref.read(deviceIdentityProvider);
              
              final packet = MeshPacket(
                msgId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                originNodeId: nodeId,
                type: 5, // Chat
                priority: 1, // NORMAL
                timestamp: DateTime.now().millisecondsSinceEpoch,
                ttl: 86400000,
                hopCount: 0,
                payload: controller.text.trim(),
              );
              
              await syncEngine.queueOutgoingPacket(packet);
              ref.invalidate(messagesRefreshProvider);
              
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('POST'),
          ),
        ],
      ),
    );
  }
}
