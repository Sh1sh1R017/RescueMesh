import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fllama/fllama.dart';
import 'hardware_profiler_service.dart';

/// Inference session state
enum InferenceStatus {
  unloaded,
  loading,
  ready,
  inferring,
  error,
}

class InferenceState {
  final InferenceStatus status;
  final ModelTier activeTier;
  final String? errorMessage;
  final String loadProgressMessage;

  const InferenceState({
    required this.status,
    required this.activeTier,
    this.errorMessage,
    this.loadProgressMessage = '',
  });

  InferenceState copyWith({
    InferenceStatus? status,
    ModelTier? activeTier,
    String? errorMessage,
    String? loadProgressMessage,
  }) {
    return InferenceState(
      status: status ?? this.status,
      activeTier: activeTier ?? this.activeTier,
      errorMessage: errorMessage ?? this.errorMessage,
      loadProgressMessage: loadProgressMessage ?? this.loadProgressMessage,
    );
  }
}

/// Module C: llama.cpp inference engine via the fllama package.
///
/// Manages GGUF model loading with OOM-safe fallback and streaming token
/// output. Thread count is bounded by physical core count to prevent
/// thermal throttling on budget phones.
class LlmInferenceService {
  static const int _maxTokens = 150;
  static const double _temperature = 0.1;
  static const double _topP = 0.9;
  static const int _contextSize = 2048;

  String? _loadedModelPath;
  String? _contextId;
  ModelTier _activeTier = ModelTier.base;
  int _threadCount = 2;

  final StreamController<InferenceState> _stateController =
      StreamController.broadcast();

  InferenceState _state = const InferenceState(
    status: InferenceStatus.unloaded,
    activeTier: ModelTier.base,
  );

  Stream<InferenceState> get stateStream => _stateController.stream;
  InferenceState get currentState => _state;

  void _emit(InferenceState s) {
    _state = s;
    _stateController.add(s);
  }

  /// Loads a GGUF model from [modelPath] as [tier].
  ///
  /// If loading fails with an OOM or any error, automatically falls back
  /// to [fallbackPath] (base 0.5B), or stays in [InferenceStatus.error]
  /// if no fallback is available.
  Future<bool> loadModel({
    required String modelPath,
    required ModelTier tier,
    String? fallbackPath,
    required int physicalCores,
  }) async {
    if (_loadedModelPath == modelPath && _contextId != null) {
      return true; // Already loaded
    }

    _threadCount = (physicalCores - 1).clamp(1, 6);

    _emit(_state.copyWith(
      status: InferenceStatus.loading,
      activeTier: tier,
      loadProgressMessage: 'Loading ${HardwareProfilerService.tierLabel(tier)} model...',
    ));

    // Release any previously loaded context
    await _releaseCurrentContext();

    try {
      final contextResult = await _initContextWithTimeout(modelPath);
      if (contextResult == null) {
        throw Exception('initContext returned null — possible OOM or corrupt file');
      }
      _contextId = contextResult;
      _loadedModelPath = modelPath;
      _activeTier = tier;

      _emit(_state.copyWith(
        status: InferenceStatus.ready,
        activeTier: tier,
        loadProgressMessage: '',
        errorMessage: null,
      ));
      debugPrint('[LLM] Model loaded: ${HardwareProfilerService.tierLabel(tier)} '
          'with $_threadCount threads');
      return true;
    } catch (e) {
      debugPrint('[LLM] Load failed for ${tier.name}: $e');

      // OOM or load failure: attempt graceful fallback to base model
      if (fallbackPath != null && tier != ModelTier.base) {
        debugPrint('[LLM] Falling back to base 0.5B model...');
        _emit(_state.copyWith(
          status: InferenceStatus.loading,
          activeTier: ModelTier.base,
          loadProgressMessage: 'Load failed. Falling back to 0.5B model...',
        ));
        return loadModel(
          modelPath: fallbackPath,
          tier: ModelTier.base,
          fallbackPath: null,
          physicalCores: physicalCores,
        );
      }

      _emit(_state.copyWith(
        status: InferenceStatus.error,
        errorMessage: 'Failed to load model: ${_sanitizeError(e)}',
      ));
      return false;
    }
  }

  /// Runs inference on [userInput], streaming tokens to [onToken].
  ///
  /// For the 0.5B model (and as a general rule), wraps the prompt in the
  /// Qwen2.5 chat template with strict system instruction to prevent drift.
  ///
  /// Returns the full response string when [done] is true via [onToken].
  Future<void> infer({
    required String userInput,
    required void Function(String token, bool done) onToken,
  }) async {
    if (_contextId == null || _state.status == InferenceStatus.error) {
      onToken('⚠️ Model not loaded. Please download a model in Settings.', true);
      return;
    }

    if (_state.status == InferenceStatus.inferring) {
      // Stop the current completion before starting a new one
      await _stopCurrentCompletion();
    }

    _emit(_state.copyWith(status: InferenceStatus.inferring));

    final wrappedPrompt = _buildPrompt(userInput);

    try {
      final fllama = Fllama.instance();
      if (fllama == null) {
        throw Exception('Fllama instance unavailable');
      }

      final buffer = StringBuffer();
      bool isDone = false;

      // Subscribe to the token stream BEFORE triggering completion
      late StreamSubscription<dynamic> sub;
      sub = fllama.onTokenStream!.listen((data) {
        if (isDone) return;

        if (data['function'] == 'completion') {
          final result = data['result'];
          final token = result['token'] as String? ?? '';
          final stop = result['stop'] as bool? ?? false;

          buffer.write(token);
          onToken(token, false);

          if (stop) {
            isDone = true;
            onToken('', true);
            _emit(_state.copyWith(status: InferenceStatus.ready));
            sub.cancel();
          }
        }
      });

      // Trigger completion
      // emitRealtimeCompletion = true enables the token stream
      await fllama.completion(
        double.parse(_contextId!),
        prompt: wrappedPrompt,
        nPredict: _maxTokens,
        temperature: _temperature,
        topP: _topP,
        nThreads: _threadCount,
        emitRealtimeCompletion: true,
        stop: ['<|im_end|>', '<|endoftext|>'],
      );
    } catch (e) {
      debugPrint('[LLM] Inference error: $e');
      _emit(_state.copyWith(status: InferenceStatus.ready));
      onToken('\n\n⚠️ Inference error: ${_sanitizeError(e)}\n'
          'The local Knowledge Base is still available below.', true);
    }
  }

  /// Stops the currently running completion without unloading the model.
  Future<void> _stopCurrentCompletion() async {
    if (_contextId == null) return;
    try {
      // stopCompletion uses named required param: contextId:
      await Fllama.instance()?.stopCompletion(contextId: double.parse(_contextId!));
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (_) {}
    _emit(_state.copyWith(status: InferenceStatus.ready));
  }

  /// Wraps the user's message in the Qwen2.5 instruction format.
  ///
  /// The 0.5B model needs rigid prompting to stay on task and avoid
  /// hallucination loops. The same template is used for all tiers for
  /// consistency.
  String _buildPrompt(String userInput) {
    return '<|im_start|>system\n'
        'You are an offline disaster medical triage assistant. '
        'Provide a concise, bulleted list of actionable steps. '
        'Answer immediately without filler text or repetition. '
        'Maximum response: $_maxTokens tokens.\n'
        '<|im_end|>\n'
        '<|im_start|>user\n'
        '$userInput\n'
        '<|im_end|>\n'
        '<|im_start|>assistant\n';
  }

  /// Initialises the llama.cpp context with a 30-second timeout.
  Future<String?> _initContextWithTimeout(String modelPath) async {
    final fllama = Fllama.instance();
    if (fllama == null) throw Exception('Fllama.instance() returned null');

    // Listen for load-progress events before calling initContext
    String? contextId;
    final completer = Completer<String?>();

    late StreamSubscription<dynamic> progressSub;
    progressSub = fllama.onTokenStream!.listen((data) {
      if (data['function'] == 'loadProgress') {
        final progress = data['result'] as double? ?? 0.0;
        _emit(_state.copyWith(
          loadProgressMessage:
              'Loading model: ${(progress * 100).toStringAsFixed(0)}%',
        ));
      }
    });

    try {
      final result = await fllama
          .initContext(
            modelPath,
            nCtx: _contextSize,
            nThreads: _threadCount,
            emitLoadProgress: true,
            useMlock: false, // avoid OOM on budget phones
          )
          .timeout(const Duration(seconds: 120));

      contextId = result?['contextId']?.toString();
      if (contextId == null || contextId == '0') {
        throw Exception('Invalid contextId returned: $contextId');
      }
    } finally {
      progressSub.cancel();
    }

    if (!completer.isCompleted) completer.complete(contextId);
    return contextId;
  }

  Future<void> _releaseCurrentContext() async {
    if (_contextId == null) return;
    try {
      await Fllama.instance()?.releaseContext(double.parse(_contextId!));
    } catch (_) {}
    _contextId = null;
    _loadedModelPath = null;
  }

  String _sanitizeError(Object e) {
    final msg = e.toString();
    if (msg.toLowerCase().contains('out of memory') ||
        msg.toLowerCase().contains('oom') ||
        msg.toLowerCase().contains('alloc')) {
      return 'Out of memory — device RAM insufficient for this model. '
          'The app will use the 0.5B fallback.';
    }
    // Truncate very long native stack traces
    return msg.length > 120 ? '${msg.substring(0, 120)}...' : msg;
  }

  ModelTier get activeTier => _activeTier;
  bool get isLoaded => _contextId != null;

  Future<void> dispose() async {
    await _releaseCurrentContext();
    try {
      Fllama.instance()?.releaseAllContexts();
    } catch (_) {}
    await _stateController.close();
  }
}
