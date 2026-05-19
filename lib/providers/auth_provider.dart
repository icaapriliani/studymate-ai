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

  // Parse Firebase exceptions into user-friendly messages in Indonesian
  String _parseException(dynamic exception) {
    final message = exception.toString();
    
    // Cloud Firestore-specific troubleshooting errors
    if (message.contains('PERMISSION_DENIED')) {
      return 'Akses Firestore ditolak. Harap pastikan aturan keamanan (Security Rules) Firestore Anda sudah diatur ke publik/mode pengujian, dan Database Firestore telah dibuat di Firebase Console.';
    } else if (message.contains('API_DISABLED') || message.contains('Firestore API has not been used')) {
      return 'API Cloud Firestore belum diaktifkan pada proyek Firebase Anda. Harap aktifkan Firestore Database melalui Firebase Console.';
    }
    
    // Firebase Authentication errors
    if (message.contains('user-not-found')) {
      return 'Tidak ada akun yang ditemukan dengan alamat email tersebut.';
    } else if (message.contains('wrong-password')) {
      return 'Kata sandi yang Anda masukkan salah.';
    } else if (message.contains('email-already-in-use')) {
      return 'Alamat email ini sudah terdaftar pada akun lain.';
    } else if (message.contains('invalid-email')) {
      return 'Format alamat email yang Anda masukkan tidak valid.';
    } else if (message.contains('weak-password')) {
      return 'Kata sandi terlalu lemah. Harap gunakan minimal 6 karakter.';
    } else if (message.contains('network-request-failed')) {
      return 'Koneksi jaringan gagal. Silakan periksa koneksi internet Anda.';
    }
    
    return message.replaceAll(RegExp(r'\[.*?\]'), '').trim();
  }
}
