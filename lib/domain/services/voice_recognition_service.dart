import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecognitionService {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  bool _isListening = false;
  
  Function(String)? onPartialResult;
  Function(String)? onFinalResult;

  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('Microphone permission denied.');
      return false;
    }

    try {
      // In a real app, you would download/unpack the model here or load from assets.
      // For MVP, we assume the model is placed in the required structure.
      final modelPath = await ModelLoader().loadFromAssets('assets/vosk-model');
      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(model: _model!, sampleRate: 16000);
      _speechService = await _vosk.initSpeechService(_recognizer!);
      
      _speechService!.onPartial().listen((event) {
        if (onPartialResult != null) {
          final Map<String, dynamic> result = jsonDecode(event);
          if (result.containsKey('partial')) {
            onPartialResult!(result['partial']);
          }
        }
      });

      _speechService!.onResult().listen((event) {
        if (onFinalResult != null) {
          final Map<String, dynamic> result = jsonDecode(event);
          if (result.containsKey('text')) {
            onFinalResult!(result['text']);
          }
        }
      });
      
      debugPrint('Voice Recognition Service Initialized successfully.');
      return true;
    } catch (e) {
      debugPrint('Failed to load Vosk model: $e. Make sure you downloaded the acoustic model to assets/vosk-model.');
      return false;
    }
  }

  Future<void> startListening() async {
    if (_speechService == null || _isListening) return;
    await _speechService!.start();
    _isListening = true;
  }

  Future<void> stopListening() async {
    if (_speechService == null || !_isListening) return;
    await _speechService!.stop();
    _isListening = false;
  }
  
  bool get isListening => _isListening;
}
