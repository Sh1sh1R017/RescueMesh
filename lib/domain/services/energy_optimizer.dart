import 'package:battery_plus/battery_plus.dart';

enum EnergyMode { PERFORMANCE, BALANCED, POWER_SAVER, ULTRA_LOW_POWER }

class EnergyOptimizer {
  final Battery _battery = Battery();

  /// Determines the current energy mode based on battery percentage.
  Future<EnergyMode> getCurrentMode() async {
    final level = await _battery.batteryLevel;

    if (level > 75) return EnergyMode.PERFORMANCE;
    if (level > 40) return EnergyMode.BALANCED;
    if (level > 15) return EnergyMode.POWER_SAVER;
    return EnergyMode.ULTRA_LOW_POWER;
  }

  /// Calculates the probability (0.0 to 1.0) that we should relay a specific message.
  /// This implements the M4 - AI Energy Optimizer specification.
  Future<double> getRelayProbability(int messagePriority) async {
    final mode = await getCurrentMode();
    double baseProbability;

    switch (mode) {
      case EnergyMode.PERFORMANCE:
        baseProbability = 1.0;
        break;
      case EnergyMode.BALANCED:
        baseProbability = 0.75;
        break;
      case EnergyMode.POWER_SAVER:
        baseProbability = 0.50;
        break;
      case EnergyMode.ULTRA_LOW_POWER:
        baseProbability = 0.25;
        break;
    }

    // Critical messages bypass some probability limits
    if (messagePriority >= 3) { // 3 = CRITICAL
      // CRITICAL floor is 0.20 at ULTRA_LOW_POWER, but we boost probability 
      // significantly to ensure life-saving messages propagate.
      return baseProbability < 0.50 ? 0.50 : baseProbability;
    }
    
    // Low priority messages on low battery get heavily throttled
    if (messagePriority == 0 && mode == EnergyMode.ULTRA_LOW_POWER) {
       return 0.05; // 5% chance to relay a non-emergency check-in on dead battery
    }

    return baseProbability;
  }
}
