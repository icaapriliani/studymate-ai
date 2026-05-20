import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity> get user;
  
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  Future<UserEntity> getCurrentUser();

  Future<UserEntity> updateProfile({
    String? displayName,
    String? nim,
    String? major,
    int? studyTargetHours,
  });

  Future<void> updateLastActive();

  Future<void> sendPasswordResetEmail(String email);
}
