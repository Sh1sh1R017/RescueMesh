import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/hardware_profiler_service.dart';
import '../domain/services/model_download_service.dart';
import '../domain/services/llm_inference_service.dart';

// ─────────────────────────────────────────────
// Shared service instances
// ─────────────────────────────────────────────

final modelDownloadServiceProvider = Provider<ModelDownloadService>((ref) {
  final service = ModelDownloadService();
  ref.onDispose(service.dispose);
  return service;
});

final llmInferenceServiceProvider = Provider<LlmInferenceService>((ref) {
  final service = LlmInferenceService();
  ref.onDispose(service.dispose);
  return service;
});

// ─────────────────────────────────────────────
// Hardware profile — loaded once at startup
// ─────────────────────────────────────────────

final hardwareProfileProvider = FutureProvider<HardwareProfile>((ref) async {
  return HardwareProfilerService.getProfile();
});

// ─────────────────────────────────────────────
// Mesh base URL — user-configurable from Settings
// ─────────────────────────────────────────────

class MeshUrlNotifier extends Notifier<String> {
  @override
  String build() => 'http://192.168.4.1:8080/models/';

  void setUrl(String url) {
    // Ensure trailing slash
    final normalised = url.endsWith('/') ? url : '$url/';
    state = normalised;
    // Propagate to the download service
    ref.read(modelDownloadServiceProvider).baseUrl = normalised;
  }
}

final meshUrlProvider = NotifierProvider<MeshUrlNotifier, String>(
  MeshUrlNotifier.new,
);

// ─────────────────────────────────────────────
// Active model tier selection
// ─────────────────────────────────────────────

class ActiveTierNotifier extends Notifier<ModelTier> {
  @override
  ModelTier build() => ModelTier.base;

  void setTier(ModelTier tier) => state = tier;
}

final activeTierProvider = NotifierProvider<ActiveTierNotifier, ModelTier>(
  ActiveTierNotifier.new,
);

// ─────────────────────────────────────────────
// Download state per tier (streamed)
// ─────────────────────────────────────────────

final downloadStateProvider =
    StreamProvider.family<DownloadState, ModelTier>((ref, tier) {
  final service = ref.watch(modelDownloadServiceProvider);
  return service.stateStream(tier);
});

// ─────────────────────────────────────────────
// Inference engine state (streamed)
// ─────────────────────────────────────────────

final inferenceStateProvider =
    StreamProvider<InferenceState>((ref) {
  final service = ref.watch(llmInferenceServiceProvider);
  return service.stateStream;
});

// ─────────────────────────────────────────────
// Model load action — called from UI
// ─────────────────────────────────────────────

/// Notifier that orchestrates model loading with automatic fallback routing.
///
/// When [loadModel] is called, it:
/// 1. Checks the requested tier's file exists locally
/// 2. Falls back to the next lower tier if missing
/// 3. Triggers [LlmInferenceService.loadModel] with the base 0.5B as fallback
class ModelLoaderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> loadModel(ModelTier requestedTier) async {
    state = const AsyncLoading();

    try {
      final downloader = ref.read(modelDownloadServiceProvider);
      final inference = ref.read(llmInferenceServiceProvider);
      final profile = await ref.read(hardwareProfileProvider.future);

      // Walk down tiers until we find one that exists locally
      final tierOrder = _tiersFromHighestTo(requestedTier);
      String? targetPath;
      ModelTier targetTier = ModelTier.base;

      for (final tier in tierOrder) {
        final path = await downloader.getLocalModelPath(tier);
        if (path != null) {
          targetPath = path;
          targetTier = tier;
          break;
        }
      }

      // Always have base as fallback
      final basePath = await downloader.getLocalModelPath(ModelTier.base);

      if (targetPath == null) {
        // No model downloaded at all — update UI state only
        state = AsyncError(
          'No model file found. Please download a model from the Settings screen.',
          StackTrace.current,
        );
        return;
      }

      final success = await inference.loadModel(
        modelPath: targetPath,
        tier: targetTier,
        fallbackPath: basePath,
        physicalCores: profile.physicalCoreCount,
      );

      if (success) {
        ref.read(activeTierProvider.notifier).setTier(inference.activeTier);
        state = const AsyncData(null);
      } else {
        state = AsyncError(
          inference.currentState.errorMessage ?? 'Failed to load model.',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Returns tiers from [highest] down to [ModelTier.base] so we try the
  /// best available model first.
  List<ModelTier> _tiersFromHighestTo(ModelTier highest) {
    switch (highest) {
      case ModelTier.enhancement2:
        return [ModelTier.enhancement2, ModelTier.enhancement1, ModelTier.base];
      case ModelTier.enhancement1:
        return [ModelTier.enhancement1, ModelTier.base];
      case ModelTier.base:
        return [ModelTier.base];
    }
  }
}

final modelLoaderProvider =
    AsyncNotifierProvider<ModelLoaderNotifier, void>(ModelLoaderNotifier.new);
