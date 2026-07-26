import 'package:battery_plus/battery_plus.dart';
import '../../core/constants/packet_constants.dart';

enum EnergyMode { performance, balanced, powerSaver, ultraLowPower }

class EnergyOptimizer {
  final Battery _battery = Battery();

  int? _cachedBatteryLevel;
  DateTime? _lastBatteryFetch;
  static const Duration _cacheTtl = Duration(seconds: 20);

  static const Map<EnergyMode, double> _modeProbability = {
    EnergyMode.performance: 1.0,
    EnergyMode.balanced: 0.75,
    EnergyMode.powerSaver: 0.50,
    EnergyMode.ultraLowPower: 0.25,
  };

  static const double _criticalMinProbability = 0.50;
  static const double _ultraLowPriorityFloor = 0.05;

  /// Fetches battery level with a 20s in-memory cache to eliminate repetitive MethodChannel IPC calls in packet loops.
  Future<int> _getBatteryLevel() async {
    final now = DateTime.now();
    if (_cachedBatteryLevel != null &&
        _lastBatteryFetch != null &&
        now.difference(_lastBatteryFetch!) < _cacheTtl) {
      return _cachedBatteryLevel!;
    }

    try {
      _cachedBatteryLevel = await _battery.batteryLevel;
      _lastBatteryFetch = now;
    } catch (_) {
      _cachedBatteryLevel ??= 50; // Safe fallback
    }

    return _cachedBatteryLevel!;
  }

  /// Determines the current energy mode based on battery percentage.
  Future<EnergyMode> getCurrentMode() async {
    final level = await _getBatteryLevel();

    if (level > 75) return EnergyMode.performance;
    if (level > 40) return EnergyMode.balanced;
    if (level > 15) return EnergyMode.powerSaver;
    return EnergyMode.ultraLowPower;
  }

  /// Calculates the probability (0.0 to 1.0) that we should relay a specific message.
  /// Implements the M4 - AI Energy Optimizer specification.
  Future<double> getRelayProbability(int messagePriority) async {
    final mode = await getCurrentMode();
    final baseProbability = _modeProbability[mode] ?? 1.0;

    // Critical messages bypass some probability limits to ensure propagation
    if (messagePriority >= PacketPriority.critical) {
      return baseProbability < _criticalMinProbability
          ? _criticalMinProbability
          : baseProbability;
    }

    // Low priority messages on low battery get heavily throttled
    if (messagePriority == PacketPriority.low && mode == EnergyMode.ultraLowPower) {
      return _ultraLowPriorityFloor; // 5% chance to relay non-emergency check-in
    }

    return baseProbability;
  }
}
