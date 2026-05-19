class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
  });

  // Empty placeholder instance
  static const empty = UserEntity(
    uid: '',
    email: '',
    displayName: '',
    photoUrl: '',
  );

  bool get isEmpty => this == UserEntity.empty;
  bool get isNotEmpty => this != UserEntity.empty;
}
