import 'package:equatable/equatable.dart';

class AiSummaryResponse extends Equatable {
  final String summary;
  final List<Question> unansweredQuestions;
  final int totalQuestionsLength;
  final int unansweredQuestionsLength;

  const AiSummaryResponse({
    required this.summary,
    required this.unansweredQuestions,
    required this.totalQuestionsLength,
    required this.unansweredQuestionsLength,
  });

  static const empty = AiSummaryResponse(
    summary: '',
    unansweredQuestions: [],
    totalQuestionsLength: 0,
    unansweredQuestionsLength: 0,
  );

  factory AiSummaryResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested data structure from API response
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return AiSummaryResponse(
      summary: data['summary'] ?? '',
      unansweredQuestions:
          (data['unAnsweredQuestions'] as List<dynamic>?)
              ?.map((q) => Question.fromJson(q))
              .toList() ??
          [],
      totalQuestionsLength: data['totalQuestionsLength'] ?? 0,
      unansweredQuestionsLength: data['unAnsweredQuestionsLength'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'unAnsweredQuestions': unansweredQuestions
          .map((q) => q.toJson())
          .toList(),
      'totalQuestionsLength': totalQuestionsLength,
      'unAnsweredQuestionsLength': unansweredQuestionsLength,
    };
  }

  AiSummaryResponse copyWith({
    String? summary,
    List<Question>? unansweredQuestions,
    int? totalQuestionsLength,
    int? unansweredQuestionsLength,
  }) {
    return AiSummaryResponse(
      summary: summary ?? this.summary,
      unansweredQuestions: unansweredQuestions ?? this.unansweredQuestions,
      totalQuestionsLength: totalQuestionsLength ?? this.totalQuestionsLength,
      unansweredQuestionsLength:
          unansweredQuestionsLength ?? this.unansweredQuestionsLength,
    );
  }

  @override
  List<Object?> get props => [
    summary,
    unansweredQuestions,
    totalQuestionsLength,
    unansweredQuestionsLength,
  ];

  @override
  String toString() {
    return 'IncidentResponse(summary: $summary, '
        'unansweredQuestions: $unansweredQuestions, '
        'totalQuestionsLength: $totalQuestionsLength, '
        'unansweredQuestionsLength: $unansweredQuestionsLength)';
  }
}

class Question extends Equatable {
  final String question;
  final String example;

  const Question({required this.question, required this.example});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] ?? '',
      example: json['example'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'question': question, 'example': example};
  }

  @override
  List<Object?> get props => [question, example];

  @override
  String toString() {
    return 'Question(question: $question, example: $example)';
  }
}
