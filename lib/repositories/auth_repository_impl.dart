import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../domain/entities/user_entity.dart';
import '../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;

  AuthRepositoryImpl({
    required FirebaseAuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService;

  UserEntity _mapFirebaseUserToEntity(fb.User? user) {
    if (user == null) {
      return UserEntity.empty;
    }
    return UserEntity(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }

  @override
  Stream<UserEntity> get user {
    return _authService.authStateChanges.map(_mapFirebaseUserToEntity);
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUserToEntity(credential.user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Create account in Firebase Auth
      final credential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user;

      if (fbUser == null) {
        throw Exception('User creation failed.');
      }

      // 2. Set display name in Firebase Auth
      await _authService.updateDisplayName(displayName);

      // 3. Save User Metadata to Firestore
      final userModel = UserModel(
        uid: fbUser.uid,
        email: email,
        displayName: displayName,
        photoUrl: '',
      );
      await _firestoreService.saveUserProfile(userModel);

      // Return local entity
      return UserEntity(
        uid: fbUser.uid,
        email: email,
        displayName: displayName,
        photoUrl: '',
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final fbUser = _authService.currentUser;
    if (fbUser == null) {
      return UserEntity.empty;
    }
    
    // Attempt to pull richer info from Firestore if available
    try {
      final dbUser = await _firestoreService.getUserProfile(fbUser.uid);
      if (dbUser != null) {
        return dbUser;
      }
    } catch (_) {
      // Fallback to FirebaseAuth user if firestore fails
    }
    
    return _mapFirebaseUserToEntity(fbUser);
  }
}
