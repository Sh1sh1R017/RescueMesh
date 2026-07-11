import 'package:sqflite/sqflite.dart';
import '../../domain/models/mesh_packet.dart';
import '../database/app_database.dart';
import 'package:flutter/foundation.dart';

class SyncEngine {
  final AppDatabase _db = AppDatabase.instance;

  /// Processes an incoming packet from another mesh node.
  /// Deduplicates based on msg_id and inserts if new.
  Future<bool> processIncomingPacket(MeshPacket packet) async {
    final db = await _db.database;

    // Check if we already have this message
    final List<Map<String, dynamic>> existing = await db.query(
      'messages',
      where: 'msg_id = ?',
      whereArgs: [packet.msgId],
    );

    if (existing.isNotEmpty) {
      // Duplicate, ignore.
      return false;
    }

    // Insert new message
    try {
      await db.insert(
        'messages',
        packet.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      
      // Note: Here we would also parse the payload depending on packet.type
      // and insert it into reports, sos_requests, etc.
      // For MVP, we just store the raw message for forwarding.
      
      return true; // Indicates this is a new message that should be forwarded further
    } catch (e) {
      debugPrint('Error inserting incoming packet: $e');
      return false;
    }
  }

  /// Retrieves messages that we need to send out.
  /// For MVP: simply fetches the most recent N messages that haven't exceeded TTL.
  Future<List<MeshPacket>> getMessagesToForward({int limit = 50}) async {
    final db = await _db.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'timestamp + ttl > ?', // Only fetch non-expired messages
      whereArgs: [currentTime],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return MeshPacket.fromMap(maps[i]);
    });
  }

  /// Called when we connect to a new peer to initiate full synchronization.
  /// In a production environment, this would exchange Bloom filters or Merkle trees.
  /// For the MVP, we just broadcast our latest messages.
  Future<List<MeshPacket>> handlePeerConnected() async {
    return await getMessagesToForward();
  }
}
