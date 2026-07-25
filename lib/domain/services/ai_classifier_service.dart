import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';

enum MessagePriority { NONE, NORMAL, HIGH, CRITICAL }
enum EmergencyCategory { MEDICAL, COLLAPSE, FIRE, FLOOD, SECURITY, WEATHER, MISSING, INFRASTRUCTURE, RESOURCES, NONE }

class ClassificationResult {
  final MessagePriority priority;
  final EmergencyCategory category;
  final double confidence;

  ClassificationResult(this.priority, this.category, this.confidence);
}

class AIClassifierService {
  Interpreter? _interpreter;
  
  // Hardcoded emergency keywords for the first-stage deterministic fallback
  final Map<String, ClassificationResult> _keywordRules = {
    'heart attack': ClassificationResult(MessagePriority.CRITICAL, EmergencyCategory.MEDICAL, 1.0),
    'shooting': ClassificationResult(MessagePriority.CRITICAL, EmergencyCategory.SECURITY, 1.0),
    'building collapsed': ClassificationResult(MessagePriority.CRITICAL, EmergencyCategory.COLLAPSE, 1.0),
    'fire spreading': ClassificationResult(MessagePriority.HIGH, EmergencyCategory.FIRE, 1.0),
    'need food': ClassificationResult(MessagePriority.NORMAL, EmergencyCategory.RESOURCES, 1.0),
  };

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/emergency_model.tflite');
      debugPrint('AI Classifier Service Initialized successfully.');
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e. Falling back to keyword-only mode.');
    }
  }

  /// Two-stage pipeline: Keywords first, then TFLite neural fallback.
  Future<ClassificationResult> classifyMessage(String messageText) async {
    final lowerMsg = messageText.toLowerCase();

    // Stage 1: Deterministic Keyword Rules (Fast path for critical emergencies)
    for (var entry in _keywordRules.entries) {
      if (lowerMsg.contains(entry.key)) {
        return entry.value;
      }
    }

    // Stage 2: TFLite Neural Model Fallback
    if (_interpreter != null) {
      try {
        // Preprocessing: Convert string to tokenized int array (simplified for MVP)
        // In a real scenario, you need the exact vocabulary dictionary mapping.
        var input = _tokenize(lowerMsg);
        
        // Output array depends on your model architecture (e.g., [1, 10] for 10 categories)
        var output = List.filled(1 * 10, 0.0).reshape([1, 10]);

        _interpreter!.run(input, output);
        
        // Post-processing
        return _parseNeuralOutput(output[0]);
      } catch (e) {
        debugPrint('TFLite inference error: $e');
      }
    }

    // Default if no model and no keywords hit
    return ClassificationResult(MessagePriority.NORMAL, EmergencyCategory.NONE, 0.0);
  }
  
  List<List<int>> _tokenize(String text) {
    // Dummy tokenizer for MVP architecture demonstration
    // The actual tokenization logic must match the Python training script.
    return [List.filled(100, 0)]; 
  }

  ClassificationResult _parseNeuralOutput(List<double> probabilities) {
    // Find argmax for category
    int bestIndex = 0;
    double maxProb = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        bestIndex = i;
      }
    }

    // Map index to Category and Priority based on training labels
    // Note: Adjust indexing to match your actual model's training labels.
    if (maxProb > 0.25) { // 25% confidence threshold from architecture specs
       // Mocked mapping for MVP
       return ClassificationResult(MessagePriority.HIGH, EmergencyCategory.values[bestIndex % EmergencyCategory.values.length], maxProb);
    }
    
    return ClassificationResult(MessagePriority.NORMAL, EmergencyCategory.NONE, maxProb);
  }
  
  void close() {
    _interpreter?.close();
  }
}
