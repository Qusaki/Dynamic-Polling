import 'package:flutter/foundation.dart';

enum QuestionType {
  rating,
  multiple_choice,
  open_ended,
}

class Option {
  final int id;
  final String text;

  Option({required this.id, required this.text});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(id: json['id'], text: json['text']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text};
  }
}

class Question {
  final int id;
  final String text;
  final QuestionType type;
  final int order;
  final List<Option> options;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.order,
    this.options = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var questionType = QuestionType.values.firstWhere(
            (e) => describeEnum(e) == json['type'].toString().toLowerCase(),
        orElse: () => QuestionType.open_ended);

    return Question(
      id: json['id'],
      text: json['text'],
      type: questionType,
      order: json['order'],
      options: json['options'] != null
          ? (json['options'] as List).map((i) => Option.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': describeEnum(type).toUpperCase(),
      'options': options.map((o) => o.text).toList(),
    };
  }
}

class Poll {
  final int id;
  final String title;
  final String? description;
  final String access_code;
  final bool is_active;
  final DateTime created_at;
  final List<Question> questions;

  Poll({
    required this.id,
    required this.title,
    this.description,
    required this.access_code,
    required this.is_active,
    required this.created_at,
    required this.questions,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      access_code: json['access_code'],
      is_active: json['is_active'],
      created_at: DateTime.parse(json['created_at']),
      questions: (json['questions'] as List)
          .map((i) => Question.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'access_code': access_code,
      'is_active': is_active,
      'created_at': created_at.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  Poll copyWith({
    int? id,
    String? title,
    String? description,
    String? access_code,
    bool? is_active,
    DateTime? created_at,
    List<Question>? questions,
  }) {
    return Poll(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      access_code: access_code ?? this.access_code,
      is_active: is_active ?? this.is_active,
      created_at: created_at ?? this.created_at, // Assign new field
      questions: questions ?? this.questions,
    );
  }
}