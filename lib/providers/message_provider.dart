import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/message_repository.dart';
import '../data/mesh/sync_engine.dart';
import '../domain/models/mesh_packet.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine();
});

final messagesRefreshProvider = StateProvider<int>((ref) => 0);

final recentMessagesProvider = FutureProvider<List<MeshPacket>>((ref) async {
  ref.watch(messagesRefreshProvider); // Watch for manual invalidation
  
  // Reactively auto-invalidate this provider when new packets are synced
  final subscription = SyncEngine.messageStream.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  final repo = ref.read(messageRepositoryProvider);
  return repo.getRecentMessages();
});

final recentAlertsProvider = FutureProvider<List<MeshPacket>>((ref) async {
  ref.watch(messagesRefreshProvider); // Watch for manual invalidation

  // Reactively auto-invalidate this provider when new packets are synced
  final subscription = SyncEngine.messageStream.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  final repo = ref.read(messageRepositoryProvider);
  return repo.getRecentAlerts();
});
