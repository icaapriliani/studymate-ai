import 'package:cloud_firestore/cloud_firestore.dart';

class QuizSessionModel {
  final String id;
  final String materialId;
  final String materialTitle;
  final DateTime createdAt;
  final bool completed;
  final int score;
  final int totalQuestions;
  final String aiFeedback;

  QuizSessionModel({
    required this.id,
    required this.materialId,
    required this.materialTitle,
    required this.createdAt,
    required this.completed,
    required this.score,
    required this.totalQuestions,
    required this.aiFeedback,
  });

  factory QuizSessionModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return QuizSessionModel(
      id: documentId,
      materialId: data['materialId'] ?? '',
      materialTitle: data['materialTitle'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: data['completed'] ?? false,
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      aiFeedback: data['aiFeedback'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'materialId': materialId,
      'materialTitle': materialTitle,
      'createdAt': Timestamp.fromDate(createdAt),
      'completed': completed,
      'score': score,
      'totalQuestions': totalQuestions,
      'aiFeedback': aiFeedback,
    };
  }

  QuizSessionModel copyWith({
    String? id,
    String? materialId,
    String? materialTitle,
    DateTime? createdAt,
    bool? completed,
    int? score,
    int? totalQuestions,
    String? aiFeedback,
  }) {
    return QuizSessionModel(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      materialTitle: materialTitle ?? this.materialTitle,
      createdAt: createdAt ?? this.createdAt,
      completed: completed ?? this.completed,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      aiFeedback: aiFeedback ?? this.aiFeedback,
    );
  }
}
