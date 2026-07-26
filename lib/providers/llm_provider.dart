import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/hardware_profiler_service.dart';
import '../domain/services/model_download_service.dart';
import '../domain/services/llm_inference_service.dart';

// ─────────────────────────────────────────────
// Single source of truth for the default mesh URL
// ─────────────────────────────────────────────

const String kDefaultMeshBaseUrl = 'http://192.168.4.1:8080/models/';

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
  String build() => kDefaultMeshBaseUrl;

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
// Active model tier — replaced 10-line Notifier class with StateProvider
// ─────────────────────────────────────────────

final activeTierProvider = StateProvider<ModelTier>((_) => ModelTier.base);

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

      // Walk tiers from requested down to base — use ModelTier.values so
      // adding a new tier never requires updating this method.
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
        ref.read(activeTierProvider.notifier).state = inference.activeTier;
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

  /// Returns tiers from [highest] down to [ModelTier.base].
  /// Driven by ModelTier.values so adding a new tier is automatic.
  static List<ModelTier> _tiersFromHighestTo(ModelTier highest) =>
      ModelTier.values
          .where((t) => t.index <= highest.index)
          .toList()
          .reversed
          .toList();
}

final modelLoaderProvider =
    AsyncNotifierProvider<ModelLoaderNotifier, void>(ModelLoaderNotifier.new);
