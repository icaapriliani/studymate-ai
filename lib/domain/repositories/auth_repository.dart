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
}
