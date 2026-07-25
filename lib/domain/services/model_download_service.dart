import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'hardware_profiler_service.dart';

/// Represents the current state of a model download.
class DownloadState {
  final ModelTier tier;
  final double progress; // 0.0 – 1.0
  final DownloadStatus status;
  final String? errorMessage;
  final String? localPath;

  const DownloadState({
    required this.tier,
    required this.progress,
    required this.status,
    this.errorMessage,
    this.localPath,
  });

  DownloadState copyWith({
    double? progress,
    DownloadStatus? status,
    String? errorMessage,
    String? localPath,
  }) {
    return DownloadState(
      tier: tier,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      localPath: localPath ?? this.localPath,
    );
  }
}

enum DownloadStatus { idle, downloading, paused, complete, error }

/// Module B: Mesh-aware resumable download manager for GGUF model files.
///
/// Downloads from a configurable base URL (default: local mesh router at
/// http://192.168.4.1:8080/models/), supports resume-on-disconnect via
/// HTTP Range headers, and reports live progress via a [StreamController].
class ModelDownloadService {
  static const String _defaultBaseUrl = 'http://192.168.4.1:8080/models/';
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 0); // streaming

  /// The active base URL — can be changed from the Settings UI.
  String baseUrl;

  final Map<ModelTier, DownloadState> _states = {};
  final Map<ModelTier, StreamController<DownloadState>> _controllers = {};
  final Map<ModelTier, CancelToken> _cancelTokens = {};

  late final Dio _dio;

  ModelDownloadService({String? baseUrl})
      : baseUrl = baseUrl ?? _defaultBaseUrl {
    _dio = Dio(
      BaseOptions(
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      ),
    );
  }

  /// Returns a [Stream] of [DownloadState] updates for [tier].
  Stream<DownloadState> stateStream(ModelTier tier) {
    _controllers.putIfAbsent(tier, () => StreamController.broadcast());
    _states.putIfAbsent(
      tier,
      () => DownloadState(
        tier: tier,
        progress: 0.0,
        status: DownloadStatus.idle,
      ),
    );
    return _controllers[tier]!.stream;
  }

  DownloadState currentState(ModelTier tier) =>
      _states[tier] ??
      DownloadState(tier: tier, progress: 0, status: DownloadStatus.idle);

  /// Starts or resumes a download for [tier].
  ///
  /// Resumption is implemented by checking if a partial file exists and
  /// sending an HTTP Range header to skip already-downloaded bytes.
  Future<void> startDownload(ModelTier tier) async {
    if (currentState(tier).status == DownloadStatus.downloading) return;

    final filename = HardwareProfilerService.tierFilename(tier);
    final savePath = await _resolveLocalPath(filename);
    final partPath = '$savePath.part';

    _emit(tier, currentState(tier).copyWith(status: DownloadStatus.downloading));

    final cancelToken = CancelToken();
    _cancelTokens[tier] = cancelToken;

    try {
      final partFile = File(partPath);
      int existingBytes = 0;
      if (await partFile.exists()) {
        existingBytes = await partFile.length();
      }

      final url = '$baseUrl$filename';
      final response = await _dio.head(url, cancelToken: cancelToken);
      final totalBytes =
          int.tryParse(response.headers.value('content-length') ?? '') ??
              HardwareProfilerService.tierApproxBytes(tier);

      // Open file in append mode if resuming
      final raf = await partFile.open(mode: existingBytes > 0 ? FileMode.append : FileMode.write);

      final options = Options(
        headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
        responseType: ResponseType.stream,
      );

      final streamResponse = await _dio.get<ResponseBody>(
        url,
        options: options,
        cancelToken: cancelToken,
      );

      int receivedBytes = existingBytes;
      final completer = Completer<void>();

      streamResponse.data!.stream.listen(
        (chunk) {
          raf.writeFromSync(chunk);
          receivedBytes += chunk.length;
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          _emit(
            tier,
            currentState(tier).copyWith(
              progress: progress,
              status: DownloadStatus.downloading,
            ),
          );
        },
        onDone: () async {
          await raf.close();
          // Rename .part → final file only when fully complete
          await partFile.rename(savePath);
          _emit(
            tier,
            currentState(tier).copyWith(
              progress: 1.0,
              status: DownloadStatus.complete,
              localPath: savePath,
            ),
          );
          completer.complete();
        },
        onError: (Object error) async {
          await raf.close();
          if (error is DioException &&
              error.type == DioExceptionType.cancel) {
            _emit(
              tier,
              currentState(tier).copyWith(status: DownloadStatus.paused),
            );
          } else {
            _emit(
              tier,
              currentState(tier).copyWith(
                status: DownloadStatus.error,
                errorMessage: error.toString(),
              ),
            );
          }
          completer.complete();
        },
        cancelOnError: false,
      );

      await completer.future;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _emit(tier, currentState(tier).copyWith(status: DownloadStatus.paused));
      } else {
        _emit(
          tier,
          currentState(tier).copyWith(
            status: DownloadStatus.error,
            errorMessage: 'Network error: ${e.message ?? e.type.name}',
          ),
        );
      }
    } catch (e) {
      _emit(
        tier,
        currentState(tier).copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Download failed: $e',
        ),
      );
    }
  }

  /// Pauses an in-progress download by cancelling the Dio token.
  /// The partial file is preserved for resumption.
  void pauseDownload(ModelTier tier) {
    _cancelTokens[tier]?.cancel('User paused download');
  }

  /// Cancels a download and deletes the partial file.
  Future<void> cancelDownload(ModelTier tier) async {
    _cancelTokens[tier]?.cancel('User cancelled download');
    final filename = HardwareProfilerService.tierFilename(tier);
    final partPath = '${await _resolveLocalPath(filename)}.part';
    final partFile = File(partPath);
    if (await partFile.exists()) await partFile.delete();
    _emit(
      tier,
      DownloadState(tier: tier, progress: 0, status: DownloadStatus.idle),
    );
  }

  /// Returns the local file path for a downloaded model, or null if not present.
  Future<String?> getLocalModelPath(ModelTier tier) async {
    final path =
        await _resolveLocalPath(HardwareProfilerService.tierFilename(tier));
    if (await File(path).exists()) return path;
    return null;
  }

  /// Resolves the app-private documents directory path for a model file.
  Future<String> _resolveLocalPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}/gguf_models');
    if (!await modelsDir.exists()) await modelsDir.create(recursive: true);
    return '${modelsDir.path}/$filename';
  }

  void _emit(ModelTier tier, DownloadState state) {
    _states[tier] = state;
    _controllers[tier]?.add(state);
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _dio.close();
  }
}
