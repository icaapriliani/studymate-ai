class QuizQuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String? userAnswer;

  QuizQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.userAnswer,
  });

  factory QuizQuestionModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return QuizQuestionModel(
      id: documentId,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
      explanation: data['explanation'] ?? '',
      userAnswer: data['userAnswer'],
    );
  }

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: '', // Generated later when saving to Firestore
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'userAnswer': userAnswer,
    };
  }

  QuizQuestionModel copyWith({
    String? id,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? userAnswer,
  }) {
    return QuizQuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      userAnswer: userAnswer ?? this.userAnswer,
    );
  }
}
