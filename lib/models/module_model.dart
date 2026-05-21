import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleModel {
  final String id;
  final String title;
  final String content;
  final int orderIndex;
  final int estimatedMinutes;
  final DateTime createdAt;

  const ModuleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.orderIndex,
    required this.estimatedMinutes,
    required this.createdAt,
  });

  factory ModuleModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime createdAtDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAtDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAtDate = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    }

    final rawContent = data['content'] ?? '';
    
    // Count words realistically (split by spaces)
    final wordsCount = rawContent.trim().split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).length;
    
    // Academic studying speed ≈ 75 words per minute.
    // E.g.: 200 words -> 3 min, 500 words -> 7 min, 1000 words -> 14 min.
    int estimated = 0;
    if (wordsCount > 0) {
      estimated = (wordsCount / 75).ceil();
      if (estimated < 1) estimated = 1;
    }

    return ModuleModel(
      id: id,
      title: data['title'] ?? '',
      content: rawContent,
      orderIndex: data['orderIndex'] ?? 0,
      estimatedMinutes: estimated > 0 ? estimated : (data['estimatedMinutes'] ?? 0),
      createdAt: createdAtDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'orderIndex': orderIndex,
      'estimatedMinutes': estimatedMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
