import 'package:flutter/material.dart';
import '../domain/entities/user_entity.dart';
import '../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserEntity _currentUser = UserEntity.empty;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository {
    // Listen to authentication state stream
    _authRepository.user.listen((UserEntity user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Getters
  UserEntity get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear previous error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign In with Email & Password
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearErrorOnly();
    try {
      _currentUser = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = _parseException(e);
      notifyListeners();
      return false;
    }
  }

  // Sign Up with Email, Password & Name
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearErrorOnly();
    try {
      _currentUser = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = _parseException(e);
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = UserEntity.empty;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = _parseException(e);
      notifyListeners();
    }
  }

  // Check current auth status on demand
  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authRepository.getCurrentUser();
    } catch (_) {
      _currentUser = UserEntity.empty;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearErrorOnly() {
    _errorMessage = null;
  }

  // Parse Firebase exceptions into user-friendly messages
  String _parseException(dynamic exception) {
    final message = exception.toString();
    if (message.contains('user-not-found')) {
      return 'No user found for that email address.';
    } else if (message.contains('wrong-password')) {
      return 'Incorrect password provided.';
    } else if (message.contains('email-already-in-use')) {
      return 'An account already exists for that email.';
    } else if (message.contains('invalid-email')) {
      return 'The email address is poorly formatted.';
    } else if (message.contains('weak-password')) {
      return 'The password is too weak.';
    } else if (message.contains('network-request-failed')) {
      return 'Network connection failed. Please check your internet connection.';
    }
    return message.replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }
}
