class Question {
  final int id;
  final Map<String, dynamic> categoryMap;
  final String difficulty;
  final Map<String, dynamic> questionMap;
  final Map<String, dynamic> choicesMap;
  final int answerIndex;
  final Map<String, dynamic> explanationMap;
  final List<String> tags;

  Question({
    required this.id,
    required this.categoryMap,
    required this.difficulty,
    required this.questionMap,
    required this.choicesMap,
    required this.answerIndex,
    required this.explanationMap,
    required this.tags,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      categoryMap: json['category'] is String ? {'ko': json['category']} : Map<String, dynamic>.from(json['category']),
      difficulty: json['difficulty'],
      questionMap: json['question'] is String ? {'ko': json['question']} : Map<String, dynamic>.from(json['question']),
      choicesMap: json['choices'] is List ? {'ko': json['choices']} : Map<String, dynamic>.from(json['choices']),
      answerIndex: json['answerIndex'],
      explanationMap: json['explanation'] is String ? {'ko': json['explanation']} : Map<String, dynamic>.from(json['explanation']),
      tags: List<String>.from(json['tags']),
    );
  }

  String getCategory(String lang) => categoryMap[lang] ?? categoryMap['ko'] ?? '';
  String getQuestion(String lang) => questionMap[lang] ?? questionMap['ko'] ?? '';
  List<String> getChoices(String lang) => List<String>.from(choicesMap[lang] ?? choicesMap['ko'] ?? []);
  String getExplanation(String lang) => explanationMap[lang] ?? explanationMap['ko'] ?? '';
}
