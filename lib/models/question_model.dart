class Question {
  final int id;
  final String category;
  final String difficulty;
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;
  final List<String> tags;

  Question({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
    required this.tags,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      category: json['category'],
      difficulty: json['difficulty'],
      question: json['question'],
      choices: List<String>.from(json['choices']),
      answerIndex: json['answerIndex'],
      explanation: json['explanation'],
      tags: List<String>.from(json['tags']),
    );
  }
}
