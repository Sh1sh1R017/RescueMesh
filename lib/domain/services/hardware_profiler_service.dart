import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Model tiers available in the SmolLM2 system.
enum ModelTier {
  /// SmolLM2-135M-Instruct-Q4_K_M.gguf (~95 MB) — ultra-compact base failsafe.
  base,

  /// SmolLM2-360M-Instruct-Q4_K_M.gguf (~240 MB) — offered on ≥ 2.5 GB RAM.
  enhancement1,

  /// SmolLM2-1.7B-Instruct-Q4_K_M.gguf (~1.0 GB) — offered on ≥ 4 GB RAM.
  enhancement2,
}

// ─────────────────────────────────────────────
// Tier specification — single source of truth
// ─────────────────────────────────────────────

class _TierSpec {
  final String label;
  final String filename;
  final int approxBytes;
  const _TierSpec(this.label, this.filename, this.approxBytes);
}

const _kMb = 1024 * 1024;
const _kGb = 1024 * 1024 * 1024;

const Map<ModelTier, _TierSpec> _kTierSpecs = {
  ModelTier.base: _TierSpec(
    'SmolLM2-135M',
    'SmolLM2-135M-Instruct-Q4_K_M.gguf',
    95 * _kMb,
  ),
  ModelTier.enhancement1: _TierSpec(
    'SmolLM2-360M',
    'SmolLM2-360M-Instruct-Q4_K_M.gguf',
    240 * _kMb,
  ),
  ModelTier.enhancement2: _TierSpec(
    'SmolLM2-1.7B',
    'SmolLM2-1.7B-Instruct-Q4_K_M.gguf',
    1024 * _kMb,
  ),
};

// Tier RAM thresholds for ultra-lightweight SmolLM execution
const double _kEnhancement2MinGb = 4.0;
const double _kEnhancement1MinGb = 2.5;

/// Result from a hardware profiling pass.
class HardwareProfile {
  final int totalRamBytes;
  final int physicalCoreCount;
  final String deviceModel;
  final ModelTier maxAllowedTier;
  final ModelTier recommendedTier;

  const HardwareProfile({
    required this.totalRamBytes,
    required this.physicalCoreCount,
    required this.deviceModel,
    required this.maxAllowedTier,
    required this.recommendedTier,
  });

  double get totalRamGb => totalRamBytes / _kGb;

  /// Number of llama.cpp threads — capped at physical cores minus 1 (max 4)
  /// to leave headroom for the UI thread and prevent thermal throttling.
  int get llamaThreadCount => (physicalCoreCount - 1).clamp(1, 4);

  @override
  String toString() =>
      'HardwareProfile(ram=${totalRamGb.toStringAsFixed(1)}GB, '
      'cores=$physicalCoreCount, tier=$maxAllowedTier, model=$deviceModel)';
}

/// Module A: Profiles device hardware and returns the appropriate SmolLM model tier.
class HardwareProfilerService {
  static const MethodChannel _channel =
      MethodChannel('com.rescuemesh/hardware');

  static HardwareProfile? _cachedProfile;

  /// Returns the hardware profile, using a cached result after the first call.
  static Future<HardwareProfile> getProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;

    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'Unknown';
    int coreCount = 4; // safe default

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceModel = '${info.manufacturer} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceModel = info.utsname.machine;
      }
    } catch (_) {
      // Non-critical — model name is cosmetic only
    }

    try {
      coreCount =
          (await _channel.invokeMethod<int>('getPhysicalCoreCount')) ?? 4;
    } catch (_) {
      // Fallback: use Dart's isolate count as proxy for logical cores
      coreCount = Platform.numberOfProcessors.clamp(2, 8);
    }

    final totalRamBytes = await _getTotalRamBytes();
    final maxAllowed = _tierForRam(totalRamBytes);

    _cachedProfile = HardwareProfile(
      totalRamBytes: totalRamBytes,
      physicalCoreCount: coreCount,
      deviceModel: deviceModel,
      maxAllowedTier: maxAllowed,
      recommendedTier: ModelTier.base,
    );

    return _cachedProfile!;
  }

  /// Determines the maximum SmolLM model tier this device can safely run.
  static ModelTier _tierForRam(int totalRamBytes) {
    final gb = totalRamBytes / _kGb;
    if (gb >= _kEnhancement2MinGb) return ModelTier.enhancement2;
    if (gb >= _kEnhancement1MinGb) return ModelTier.enhancement1;
    return ModelTier.base;
  }

  /// Queries total physical RAM via MethodChannel (Android ActivityManager)
  /// with a safe fallback to 3 GB if the channel is unavailable.
  static Future<int> _getTotalRamBytes() async {
    try {
      final bytes = await _channel.invokeMethod<int>('getTotalRamBytes');
      if (bytes != null && bytes > 0) return bytes;
    } catch (_) {
      // Channel not yet implemented or running on emulator
    }
    return 3 * _kGb; // Conservative fallback: assume low-memory device
  }

  // ─────────────────────────────────────────────
  // Tier metadata accessors — driven by SmolLM _kTierSpecs
  // ─────────────────────────────────────────────

  /// Human-readable model size label (e.g. "SmolLM2-360M").
  static String tierLabel(ModelTier tier) =>
      _kTierSpecs[tier]!.label;

  /// GGUF filename for download and local storage.
  static String tierFilename(ModelTier tier) =>
      _kTierSpecs[tier]!.filename;

  /// Approximate compressed size in bytes for UI progress display.
  static int tierApproxBytes(ModelTier tier) =>
      _kTierSpecs[tier]!.approxBytes;
}
