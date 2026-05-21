import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleProgressModel {
  final String moduleId;
  final String materialId;
  final bool completed;
  final DateTime completedAt;
  final DateTime lastReadAt;

  const ModuleProgressModel({
    required this.moduleId,
    required this.materialId,
    required this.completed,
    required this.completedAt,
    required this.lastReadAt,
  });

  factory ModuleProgressModel.fromFirestore(Map<String, dynamic> data, String moduleId) {
    DateTime completedAtDate = DateTime.now();
    if (data['completedAt'] is Timestamp) {
      completedAtDate = (data['completedAt'] as Timestamp).toDate();
    } else if (data['completedAt'] is String) {
      completedAtDate = DateTime.tryParse(data['completedAt'] as String) ?? DateTime.now();
    }

    DateTime lastReadAtDate = DateTime.now();
    if (data['lastReadAt'] is Timestamp) {
      lastReadAtDate = (data['lastReadAt'] as Timestamp).toDate();
    } else if (data['lastReadAt'] is String) {
      lastReadAtDate = DateTime.tryParse(data['lastReadAt'] as String) ?? DateTime.now();
    }

    return ModuleProgressModel(
      moduleId: moduleId,
      materialId: data['materialId'] ?? '',
      completed: data['completed'] ?? false,
      completedAt: completedAtDate,
      lastReadAt: lastReadAtDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'materialId': materialId,
      'completed': completed,
      'completedAt': Timestamp.fromDate(completedAt),
      'lastReadAt': Timestamp.fromDate(lastReadAt),
    };
  }
}
