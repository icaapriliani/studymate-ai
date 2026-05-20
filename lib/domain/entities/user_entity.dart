class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String? nim;
  final String? major;
  final int? studyTargetHours;
  final DateTime? createdAt;
  final DateTime? lastActive;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.nim,
    this.major,
    this.studyTargetHours,
    this.createdAt,
    this.lastActive,
  });

  // Empty placeholder instance
  static const empty = UserEntity(
    uid: '',
    email: '',
    displayName: '',
    photoUrl: '',
    nim: null,
    major: null,
    studyTargetHours: null,
    createdAt: null,
    lastActive: null,
  );

  bool get isEmpty => this == UserEntity.empty;
  bool get isNotEmpty => this != UserEntity.empty;
}
