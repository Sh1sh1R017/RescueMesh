import '../models/first_aid_topic.dart';
import '../../data/knowledge_base/first_aid_topics.dart';

export '../models/first_aid_topic.dart';

/// Offline First Aid Knowledge Base service.
/// Uses multi-keyword scoring with partial matching for fast, reliable offline NLP.
class FirstAidLlmService {
  final List<FirstAidTopic> _knowledgeBase;

  FirstAidLlmService({List<FirstAidTopic>? knowledgeBase})
      : _knowledgeBase = knowledgeBase ?? kFirstAidTopics;

  /// Processes a natural language query offline and returns the best first aid match.
  String query(String userMessage) {
    final cleaned = userMessage.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final tokens = cleaned.split(RegExp(r'\s+'));

    FirstAidTopic? bestMatch;
    int highestScore = 0;

    for (final topic in _knowledgeBase) {
      int score = 0;
      for (final word in tokens) {
        if (word.length < 3) continue;
        for (final keyword in topic.keywords) {
          if (keyword == word) {
            score += 3; // Exact match
          } else if (keyword.contains(word) || word.contains(keyword)) {
            score += 2; // Partial match
          } else if (keyword.split(' ').contains(word)) {
            score += 1; // Word in multi-word keyword
          }
        }
      }
      if (score > highestScore) {
        highestScore = score;
        bestMatch = topic;
      }
    }

    if (bestMatch != null && highestScore >= 2) {
      final buffer = StringBuffer();
      buffer.writeln('### 🧠 ${bestMatch.title}');
      buffer.writeln('*${bestMatch.category}*\n');
      buffer.writeln('${bestMatch.summary}\n');

      buffer.writeln('**📋 Treatment Steps:**');
      for (int i = 0; i < bestMatch.steps.length; i++) {
        buffer.writeln('${i + 1}. ${bestMatch.steps[i]}');
      }

      if (bestMatch.contraindications.isNotEmpty) {
        _writeBulletSection(buffer, '⚠️ CRITICAL — DO NOT DO:', bestMatch.contraindications);
      }

      if (bestMatch.whenToEvacuate.isNotEmpty) {
        _writeBulletSection(buffer, '🚑 EVACUATE / SEEK MEDICAL CARE IF:', bestMatch.whenToEvacuate);
      }

      return buffer.toString();
    }

    final suggestions = topicTitles.map((title) => '* $title').join('\n');
    return '### 🧠 OFFLINE ASSISTANT: Topic Not Recognised\n\n'
        'I couldn\'t confidently match your query. I have detailed protocols for:\n\n'
        '$suggestions\n\n'
        '**Try asking:** *"tear gas eyes"*, *"severe bleeding"*, *"rubber bullet chest"*, *"crowd crush"*, *"arrest rights"*';
  }

  void _writeBulletSection(StringBuffer buffer, String header, List<String> items) {
    buffer.writeln('\n**$header**');
    for (final item in items) {
      buffer.writeln('* $item');
    }
  }

  /// Returns all topic titles for quick action chips in the UI.
  List<String> get topicTitles => _knowledgeBase.map((t) => t.title).toList();
}
