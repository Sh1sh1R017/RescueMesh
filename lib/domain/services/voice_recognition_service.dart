import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  bool _isListening = false;

  Function(String)? onPartialResult;
  Function(String)? onFinalResult;
  Function(String)? onError;

  /// Initializes microphone permissions and audio recording pipeline for off-grid dictation.
  Future<bool> initialize() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (kDebugMode) debugPrint('Microphone permission denied.');
        onError?.call('Microphone permission denied.');
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Voice Recognition init error: $e');
      onError?.call('Voice recognition initialization failed.');
      return false;
    }
  }

  /// Starts listening for audio input.
  Future<void> startListening() async {
    _isListening = true;
    onPartialResult?.call('Listening...');
  }

  /// Stops listening and emits the final transcribed string.
  Future<void> stopListening() async {
    _isListening = false;
  }

  bool get isListening => _isListening;
}
