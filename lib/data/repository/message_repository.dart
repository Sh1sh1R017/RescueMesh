import '../../domain/models/mesh_packet.dart';
import '../database/app_database.dart';

class MessageRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<MeshPacket>> getRecentMessages({int limit = 50}) async {
    final db = await _db.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Uses idx_messages_expires_at B-tree index for O(log N) lookup
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'expires_at > ?',
      whereArgs: [currentTime],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => MeshPacket.fromMap(map)).toList();
  }

  Future<List<MeshPacket>> getRecentAlerts({int limit = 10}) async {
    final db = await _db.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Uses idx_messages_priority_expires index
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'expires_at > ? AND priority >= ?',
      whereArgs: [currentTime, 1], // priority >= 1
      orderBy: 'priority DESC, timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => MeshPacket.fromMap(map)).toList();
  }
}
