import 'dart:async';
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
  static const int _maxSeenCacheSize = 5000;

  /// Bounded in-memory hash set for nanosecond O(1) deduplication without disk reads.
  final Set<String> _seenMsgIds = <String>{};

  static final StreamController<MeshPacket> _messageStreamController =
      StreamController<MeshPacket>.broadcast();
  static Stream<MeshPacket> get messageStream => _messageStreamController.stream;

  /// Queues a locally generated packet for outward transmission.
  Future<bool> queueOutgoingPacket(MeshPacket packet) async {
    final db = await _db.database;
    try {
      await db.insert(
        'messages',
        packet.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _seenMsgIds.add(packet.msgId);
      _messageStreamController.add(packet);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error queueing outgoing packet: $e');
      return false;
    }
  }

  /// Processes an incoming packet from another mesh node.
  /// Fast O(1) in-memory check -> Direct SQLite insert with ConflictAlgorithm.ignore.
  Future<bool> processIncomingPacket(MeshPacket packet) async {
    // 1. Instant O(1) memory deduplication
    if (_seenMsgIds.contains(packet.msgId)) {
      return false;
    }

    // 2. Reject expired packets immediately
    if (packet.isExpired) {
      return false;
    }

    final db = await _db.database;

    try {
      final rowsInserted = await db.insert(
        'messages',
        packet.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      _seenMsgIds.add(packet.msgId);
      if (_seenMsgIds.length > _maxSeenCacheSize) {
        _seenMsgIds.remove(_seenMsgIds.first); // Maintain bounded cache
      }

      if (rowsInserted > 0) {
        _messageStreamController.add(packet);
        return true; // New message to relay
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error inserting incoming packet: $e');
      return false;
    }
  }

  /// Bulk batch processing for peer synchronization bursts.
  Future<List<MeshPacket>> processIncomingBatch(List<MeshPacket> packets) async {
    final db = await _db.database;
    final List<MeshPacket> newPackets = [];

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final packet in packets) {
        if (!_seenMsgIds.contains(packet.msgId) && !packet.isExpired) {
          batch.insert(
            'messages',
            packet.toMap(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          _seenMsgIds.add(packet.msgId);
          newPackets.add(packet);
        }
      }
      await batch.commit(noResult: true);
    });

    for (final pkt in newPackets) {
      _messageStreamController.add(pkt);
    }
    return newPackets;
  }

  /// Retrieves non-expired messages for relay transmission ordered by priority.
  /// Uses B-tree indexed expires_at column.
  Future<List<MeshPacket>> getMessagesToForward({int limit = 50}) async {
    final db = await _db.database;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Uses idx_messages_priority_expires B-tree index
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'expires_at > ?',
      whereArgs: [currentTime],
      orderBy: 'priority DESC, timestamp ASC',
      limit: limit,
    );

    final List<MeshPacket> packetsToForward = [];

    for (final map in maps) {
      final MeshPacket packet = MeshPacket.fromMap(map);

      // M3: Check hop count limits
      if (packet.hopCount >= maxHopCount) {
        if (kDebugMode) {
          debugPrint('Hop limit reached for packet ${packet.msgId}, dropping.');
        }
        continue;
      }

      // M4: Apply AI Energy Optimizer policy
      final double relayProb =
          await _energyOptimizer.getRelayProbability(packet.priority);
      final double roll = _random.nextDouble();

      if (roll <= relayProb) {
        packetsToForward.add(packet.copyWith(hopCount: packet.hopCount + 1));
      } else if (kDebugMode) {
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
