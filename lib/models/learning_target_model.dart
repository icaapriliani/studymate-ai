import 'package:cloud_firestore/cloud_firestore.dart';

class LearningTargetModel {
  final int weeklyQuizTarget;
  final DateTime updatedAt;

  const LearningTargetModel({
    required this.weeklyQuizTarget,
    required this.updatedAt,
  });

  factory LearningTargetModel.fromFirestore(Map<String, dynamic> data) {
    return LearningTargetModel(
      weeklyQuizTarget: data['weeklyQuizTarget'] as int? ?? 5,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'weeklyQuizTarget': weeklyQuizTarget,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LearningTargetModel.defaultTarget() {
    return LearningTargetModel(
      weeklyQuizTarget: 5,
      updatedAt: DateTime.now(),
    );
  }

  LearningTargetModel copyWith({
    int? weeklyQuizTarget,
    DateTime? updatedAt,
  }) {
    return LearningTargetModel(
      weeklyQuizTarget: weeklyQuizTarget ?? this.weeklyQuizTarget,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
