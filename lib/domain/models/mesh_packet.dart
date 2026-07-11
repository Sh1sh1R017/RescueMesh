import 'dart:convert';

/// Represents a single unit of data transmitted over the BLE Mesh.
class MeshPacket {
  final String msgId;
  final String originNodeId;
  final int type; // 1=SOS, 2=Report, 3=Missing, 4=Resource, 5=Chat
  final int priority; // 0=NONE, 1=NORMAL, 2=HIGH, 3=CRITICAL
  final int timestamp;
  final int ttl;
  final int hopCount;
  final String payload; // Serialized JSON of the actual data
  final String? signature;

  MeshPacket({
    required this.msgId,
    required this.originNodeId,
    required this.type,
    required this.priority,
    required this.timestamp,
    required this.ttl,
    required this.hopCount,
    required this.payload,
    this.signature,
  });

  MeshPacket copyWith({
    String? msgId,
    String? originNodeId,
    int? type,
    int? priority,
    int? timestamp,
    int? ttl,
    int? hopCount,
    String? payload,
    String? signature,
  }) {
    return MeshPacket(
      msgId: msgId ?? this.msgId,
      originNodeId: originNodeId ?? this.originNodeId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
      hopCount: hopCount ?? this.hopCount,
      payload: payload ?? this.payload,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'msg_id': msgId,
      'origin_node_id': originNodeId,
      'type': type,
      'priority': priority,
      'timestamp': timestamp,
      'ttl': ttl,
      'hop_count': hopCount,
      'payload': payload,
      'signature': signature,
    };
  }

  factory MeshPacket.fromMap(Map<String, dynamic> map) {
    return MeshPacket(
      msgId: map['msg_id'] ?? '',
      originNodeId: map['origin_node_id'] ?? '',
      type: map['type']?.toInt() ?? 0,
      priority: map['priority']?.toInt() ?? 1, // Default to NORMAL
      timestamp: map['timestamp']?.toInt() ?? 0,
      ttl: map['ttl']?.toInt() ?? 0,
      hopCount: map['hop_count']?.toInt() ?? 0,
      payload: map['payload'] ?? '',
      signature: map['signature'],
    );
  }

  String toJson() => json.encode(toMap());

  factory MeshPacket.fromJson(String source) => MeshPacket.fromMap(json.decode(source));

  /// Converts packet to bytes for BLE transmission.
  /// For the MVP we use UTF-8 JSON. In production, this should be Protobuf.
  List<int> toBleBytes() {
    return utf8.encode(toJson());
  }

  factory MeshPacket.fromBleBytes(List<int> bytes) {
    return MeshPacket.fromJson(utf8.decode(bytes));
  }
}
