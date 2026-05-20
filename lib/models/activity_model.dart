import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String type; // "chat" | "material"
  final String title;
  final DateTime timestamp;

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.timestamp,
  });

  factory ActivityModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    final timestampField = data['timestamp'];
    DateTime timestamp;
    if (timestampField is Timestamp) {
      timestamp = timestampField.toDate();
    } else if (timestampField is String) {
      timestamp = DateTime.tryParse(timestampField) ?? DateTime.now();
    } else {
      timestamp = DateTime.now();
    }

    return ActivityModel(
      id: documentId,
      type: data['type'] as String? ?? 'chat',
      title: data['title'] as String? ?? '',
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'title': title,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
