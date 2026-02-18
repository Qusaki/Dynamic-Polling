
class PollPublic {
  final int id;
  final String title;
  final String? description;
  final List<Question> questions;
  final bool isActive;

  PollPublic({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
    required this.isActive,
  });

  factory PollPublic.fromJson(Map<String, dynamic> json) {
    return PollPublic(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      isActive: json['is_active'] ?? false,
    );
  }
}

class Question {
  final int id;
  final String text;
  final String type; // 'RATING', 'MULTIPLE_CHOICE', 'OPEN_ENDED'
  final int order;
  final List<Option> options;
  final int? wordLimit;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.order,
    required this.options,
    this.wordLimit,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      type: json['type'],
      order: json['order'],
      options: (json['options'] as List)
          .map((o) => Option.fromJson(o))
          .toList(),
      wordLimit: json['word_limit'],
    );
  }
}

class Option {
  final int id;
  final String text;

  Option({required this.id, required this.text});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'],
      text: json['text'],
    );
  }
}
