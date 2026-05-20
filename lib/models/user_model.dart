import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.photoUrl,
    super.nim,
    super.major,
    super.studyTargetHours,
    super.createdAt,
    super.lastActive,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      nim: data['nim'] as String?,
      major: data['major'] as String?,
      studyTargetHours: data['studyTargetHours'] as int?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      if (nim != null) 'nim': nim,
      if (major != null) 'major': major,
      if (studyTargetHours != null) 'studyTargetHours': studyTargetHours,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      nim: entity.nim,
      major: entity.major,
      studyTargetHours: entity.studyTargetHours,
      createdAt: entity.createdAt,
      lastActive: entity.lastActive,
    );
  }
}
