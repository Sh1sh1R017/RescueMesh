import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/mesh_packet.dart';
import '../database/app_database.dart';
import '../../domain/services/energy_optimizer.dart';
import 'package:flutter/foundation.dart';

class SyncEngine {
  final AppDatabase _db = AppDatabase.instance;
  final EnergyOptimizer _energyOptimizer = EnergyOptimizer();
  final Random _random = Random();
  
  static const int maxHopCount = 8;

  /// Queues a locally generated packet for outward transmission
  Future<bool> queueOutgoingPacket(MeshPacket packet) async {
    final db = await _db.database;
    try {
      await db.insert(
        'messages',
        packet.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      debugPrint('Error queueing outgoing packet: $e');
      return false;
    }
  }

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
      
      return true; // Indicates this is a new message that should be forwarded further
    } catch (e) {
      debugPrint('Error inserting incoming packet: $e');
      return false;
    }
  }

  /// Retrieves messages that we need to send out.
  /// Enforces Radio-Level Emergency Preemption by ordering by PRIORITY DESC.
  /// Applies AI Energy Optimizer to probabilistically drop packets based on battery state.
  Future<List<MeshPacket>> getMessagesToForward({int limit = 50}) async {
    final db = await _db.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Priority Queue: CRITICAL (3) drops before NORMAL (1)
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'timestamp + ttl > ?', // Only fetch non-expired messages
      whereArgs: [currentTime],
      orderBy: 'priority DESC, timestamp ASC', // Emergency Preemption
      limit: limit,
    );

    List<MeshPacket> packetsToForward = [];

    for (var map in maps) {
      MeshPacket packet = MeshPacket.fromMap(map);
      
      // M3: Check hop count limits
      if (packet.hopCount >= maxHopCount) {
        debugPrint('Hop limit reached for packet ${packet.msgId}, dropping.');
        continue;
      }
      
      // M4: Apply AI Energy Optimizer policy
      double relayProb = await _energyOptimizer.getRelayProbability(packet.priority);
      double roll = _random.nextDouble();
      
      if (roll <= relayProb) {
        packetsToForward.add(packet.copyWith(hopCount: packet.hopCount + 1));
      } else {
        debugPrint('Energy Optimizer dropped packet ${packet.msgId} to save battery.');
      }
    }

    return packetsToForward;
  }

  /// Called when we connect to a new peer to initiate full synchronization.
  Future<List<MeshPacket>> handlePeerConnected() async {
    return await getMessagesToForward();
  }
}
