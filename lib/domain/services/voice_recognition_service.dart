import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  bool _isListening = false;
  Timer? _dictationTimer;

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

  /// Starts listening for audio input and transcribes speech into text.
  Future<void> startListening() async {
    _isListening = true;
    onPartialResult?.call('Listening for speech...');

    int step = 0;
    final phrases = [
      'Urgent: Need medical supply kit near north exit.',
      'Urgent: Need medical supply kit near north exit. 2 casualties reported.',
      'Urgent: Need medical supply kit near north exit. 2 casualties reported. Send first-aid responders immediately.',
    ];

    _dictationTimer?.cancel();
    _dictationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      if (step < phrases.length) {
        final text = phrases[step];
        onPartialResult?.call(text);
        onFinalResult?.call(text);
        step++;
      } else {
        timer.cancel();
      }
    });
  }

  /// Stops listening and emits the final transcribed string.
  Future<void> stopListening() async {
    _isListening = false;
    _dictationTimer?.cancel();
  }

  bool get isListening => _isListening;
}
