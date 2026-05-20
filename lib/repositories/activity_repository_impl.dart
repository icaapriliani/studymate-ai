import '../domain/repositories/activity_repository.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityService _activityService;

  ActivityRepositoryImpl({required ActivityService activityService})
      : _activityService = activityService;

  @override
  Future<void> saveActivity(String uid, String type, String title, DateTime timestamp) async {
    try {
      await _activityService.saveActivity(uid, type, title, timestamp);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Stream<List<ActivityModel>> listenToActivities(String uid) {
    return _activityService.listenToActivities(uid).map((rawList) {
      return rawList.map((raw) => ActivityModel.fromFirestore(raw, raw['id'] as String)).toList();
    }).handleError((e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    });
  }

  @override
  Future<List<ActivityModel>> getActivities(String uid) async {
    try {
      final rawList = await _activityService.getActivities(uid);
      return rawList.map((raw) => ActivityModel.fromFirestore(raw, raw['id'] as String)).toList();
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  /// Low-level database error translation into helpful Indonesian messages.
  String _mapErrorToUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission_denied') ||
        errorString.contains('permission-denied') ||
        errorString.contains('rules')) {
      return 'Akses database ditolak. Harap pastikan aturan keamanan (Security Rules) Firestore Anda sudah dikonfigurasi ke publik/mode pengujian di Firebase Console.';
    }

    if (errorString.contains('api_disabled') ||
        errorString.contains('firestore api has not been used') ||
        errorString.contains('not-found')) {
      return 'Layanan Cloud Firestore belum diaktifkan pada proyek Firebase Anda. Harap buat database Firestore di Firebase Console.';
    }

    return 'Terjadi kesalahan sistem saat mengakses data aktivitas: $error';
  }
}
