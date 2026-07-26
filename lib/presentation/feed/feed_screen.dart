import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../core/constants/packet_constants.dart';
import '../../providers/message_provider.dart';
import '../../providers/device_identity_provider.dart';
import '../../domain/models/mesh_packet.dart';
import '../../domain/services/voice_recognition_service.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

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
                return FeedTile(
                  key: ValueKey(packet.msgId),
                  packet: packet,
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
          Semantics(
            button: true,
            label: 'Voice Dictation',
            hint: 'Record hands-free emergency voice note',
            child: FloatingActionButton(
              heroTag: 'voice_btn',
              onPressed: () => _showVoiceDictationDialog(context, ref),
              child: const Icon(Icons.mic),
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            button: true,
            label: 'Compose Post',
            hint: 'Compose custom emergency post for BLE mesh broadcast',
            child: FloatingActionButton.extended(
              heroTag: 'post_btn',
              onPressed: () => _showComposeDialog(context, ref),
              icon: const Icon(Icons.edit),
              label: const Text('POST'),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoiceDictationDialog(BuildContext context, WidgetRef ref) {
    final voiceService = VoiceRecognitionService();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          voiceService.onFinalResult = (text) {
            textController.text = text;
            setDialogState(() {});
          };
          voiceService.onPartialResult = (text) {
            textController.text = text;
            setDialogState(() {});
          };

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.mic, color: AppTheme.criticalColor),
                SizedBox(width: 8),
                Text('Voice Command & Dictation'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tap START DICTATION and speak your emergency report:'),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Transcribed speech will appear here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (voiceService.isListening) {
                        await voiceService.stopListening();
                        setDialogState(() {});
                      } else {
                        final granted = await voiceService.initialize();
                        if (granted) {
                          await voiceService.startListening();
                          setDialogState(() {});
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Microphone permission required for dictation.')),
                            );
                          }
                        }
                      }
                    },
                    icon: Icon(voiceService.isListening ? Icons.stop : Icons.record_voice_over),
                    label: Text(voiceService.isListening ? 'STOP RECORDING' : 'START DICTATION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: voiceService.isListening ? Colors.red : AppTheme.criticalColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  voiceService.stopListening();
                  Navigator.pop(dialogContext);
                },
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;

                  await voiceService.stopListening();
                  final syncEngine = ref.read(syncEngineProvider);
                  final nodeId = ref.read(deviceIdentityProvider);

                  final packet = MeshPacket(
                    msgId: 'voice_${DateTime.now().millisecondsSinceEpoch}',
                    originNodeId: nodeId,
                    type: PacketType.chat,
                    priority: PacketPriority.normal,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    ttl: kDefaultTtlMs,
                    hopCount: 0,
                    payload: '[VOICE NOTE] $text',
                  );

                  await syncEngine.queueOutgoingPacket(packet);
                  ref.invalidate(messagesRefreshProvider);

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice note posted to mesh feed.')),
                  );
                },
                child: const Text('POST VOICE NOTE'),
              ),
            ],
          );
        },
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
                type: PacketType.chat,
                priority: PacketPriority.normal,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                ttl: kDefaultTtlMs,
                hopCount: 0,
                payload: controller.text.trim(),
              );

              await syncEngine.queueOutgoingPacket(packet);
              ref.invalidate(messagesRefreshProvider);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('POST'),
          ),
        ],
      ),
    );
  }
}

/// Independent StatelessWidget for Feed items to ensure tight rebuild scoping.
class FeedTile extends StatelessWidget {
  final MeshPacket packet;

  const FeedTile({super.key, required this.packet});

  IconData _getIconForType(int type) {
    switch (type) {
      case PacketType.sos:
        return Icons.medical_services;
      case PacketType.report:
        return Icons.warning_amber_rounded;
      case PacketType.resource:
        return Icons.water_drop;
      default:
        return Icons.message;
    }
  }

  Color _getColorForType(int type, BuildContext context) {
    if (type == PacketType.sos) return AppTheme.criticalColor;
    return Theme.of(context).colorScheme.onSurface;
  }

  String _getTypeString(int type) {
    switch (type) {
      case PacketType.sos:
        return 'SOS';
      case PacketType.report:
        return 'Report';
      case PacketType.missing:
        return 'Missing';
      case PacketType.resource:
        return 'Resource';
      default:
        return 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(packet.type, context);
    final typeStr = _getTypeString(packet.type);
    final timeStr = relativeTime(packet.timestamp);
    final nodeShort = packet.originNodeId.isEmpty
        ? "Local"
        : packet.originNodeId.substring(0, min(packet.originNodeId.length, 6));

    return Semantics(
      label: '$typeStr post from Node $nodeShort: ${packet.payload}, $timeStr ago',
      child: ListTile(
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
                  Icon(Icons.wifi_tethering, size: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                  const SizedBox(width: 2),
                  Text(
                    'Node: $nodeShort',
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
      ),
    );
  }
}
