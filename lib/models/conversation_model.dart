import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a single Chat Conversation document in Cloud Firestore.
class ConversationModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to instantiate a [ConversationModel] from Firestore document data.
  factory ConversationModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseTimestamp(dynamic field) {
      if (field is Timestamp) {
        return field.toDate();
      } else if (field is DateTime) {
        return field;
      }
      return DateTime.now();
    }

    return ConversationModel(
      id: id,
      title: data['title'] as String? ?? 'Obrolan Baru',
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
    );
  }

  /// Converts the [ConversationModel] instance into a map structure suitable for Firestore writes.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
