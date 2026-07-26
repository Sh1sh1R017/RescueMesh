/// Shared packet type and priority constants.
///
/// Replaces magic integers scattered across app.dart, feed_screen.dart,
/// dashboard_screen.dart, and any future screens.
library;

/// Integer codes for [MeshPacket.type].
abstract final class PacketType {
  static const int sos = 1;
  static const int report = 2;
  static const int missing = 3;
  static const int resource = 4;
  static const int chat = 5;
}

/// Integer codes for [MeshPacket.priority].
abstract final class PacketPriority {
  static const int low = 0;
  static const int normal = 1;
  static const int high = 2;
  static const int critical = 3;
}

/// Default TTL for outgoing packets: 24 hours in milliseconds (86,400,000 ms).
const int kDefaultTtlMs = 86400000;
