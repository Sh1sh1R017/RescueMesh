import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';

enum MessagePriority { none, normal, high, critical }
enum EmergencyCategory {
  medical,
  collapse,
  fire,
  flood,
  security,
  weather,
  missing,
  infrastructure,
  resources,
  none,
}

class ClassificationResult {
  final MessagePriority priority;
  final EmergencyCategory category;
  final double confidence;

  const ClassificationResult(this.priority, this.category, this.confidence);
}

class AIClassifierService {
  Interpreter? _interpreter;

  // Hardcoded emergency keywords for the first-stage deterministic fallback
  static const Map<String, ClassificationResult> _keywordRules = {
    'heart attack': ClassificationResult(MessagePriority.critical, EmergencyCategory.medical, 1.0),
    'shooting': ClassificationResult(MessagePriority.critical, EmergencyCategory.security, 1.0),
    'building collapsed': ClassificationResult(MessagePriority.critical, EmergencyCategory.collapse, 1.0),
    'fire spreading': ClassificationResult(MessagePriority.high, EmergencyCategory.fire, 1.0),
    'need food': ClassificationResult(MessagePriority.normal, EmergencyCategory.resources, 1.0),
  };

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/emergency_model.tflite');
      if (kDebugMode) {
        debugPrint('AI Classifier Service Initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load TFLite model: $e. Falling back to keyword-only mode.');
      }
    }
  }

  /// Two-stage pipeline: Keywords first, then TFLite neural fallback.
  Future<ClassificationResult> classifyMessage(String messageText) async {
    final lowerMsg = messageText.toLowerCase();

    // Stage 1: Deterministic Keyword Rules (Fast path for critical emergencies)
    for (final entry in _keywordRules.entries) {
      if (lowerMsg.contains(entry.key)) {
        return entry.value;
      }
    }

    // Stage 2: TFLite Neural Model Fallback
    if (_interpreter != null) {
      try {
        var input = _tokenize(lowerMsg);
        var output = List.filled(1 * 10, 0.0).reshape([1, 10]);

        _interpreter!.run(input, output);

        return _parseNeuralOutput(output[0]);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TFLite inference error: $e');
        }
      }
    }

    // Default if no model and no keywords hit
    return const ClassificationResult(MessagePriority.normal, EmergencyCategory.none, 0.0);
  }

  List<List<int>> _tokenize(String text) {
    // Dummy tokenizer for MVP architecture demonstration
    return [List.filled(100, 0)];
  }

  ClassificationResult _parseNeuralOutput(List<double> probabilities) {
    int bestIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        bestIndex = i;
      }
    }

    if (maxProb > 0.25) {
      return ClassificationResult(
        MessagePriority.high,
        EmergencyCategory.values[bestIndex % EmergencyCategory.values.length],
        maxProb,
      );
    }

    return ClassificationResult(MessagePriority.normal, EmergencyCategory.none, maxProb);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
