import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // "quiz_completed" | "streak" | "learning_target" | "ai_feedback" | "system"
  final bool isRead;
  final DateTime createdAt;

  // Types constants
  static const String typeQuizCompleted = 'quiz_completed';
  static const String typeStreak = 'streak';
  static const String typeLearningTarget = 'learning_target';
  static const String typeAiFeedback = 'ai_feedback';
  static const String typeSystem = 'system';

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    final createdAtField = data['createdAt'];
    DateTime createdAt;
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is String) {
      createdAt = DateTime.tryParse(createdAtField) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return NotificationModel(
      id: documentId,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? typeSystem,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
