/// Domain model representing an offline first-aid protocol.
class FirstAidTopic {
  final String title;
  final String category;
  final String summary;
  final List<String> steps;
  final List<String> keywords;
  final List<String> contraindications;
  final List<String> whenToEvacuate;

  const FirstAidTopic({
    required this.title,
    required this.category,
    required this.summary,
    required this.steps,
    required this.keywords,
    this.contraindications = const [],
    this.whenToEvacuate = const [],
  });
}
