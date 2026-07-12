import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  bool _isListening = false;
  
  Function(String)? onPartialResult;
  Function(String)? onFinalResult;

  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('Microphone permission denied.');
      return false;
    }
    debugPrint('Voice Recognition Service initialized as a stub. Vosk model removed due to build conflicts.');
    return true;
  }

  Future<void> startListening() async {
    _isListening = true;
  }

  Future<void> stopListening() async {
    _isListening = false;
  }
  
  bool get isListening => _isListening;
}
