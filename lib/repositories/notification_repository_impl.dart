import '../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationService _notificationService;

  NotificationRepositoryImpl({required NotificationService notificationService})
      : _notificationService = notificationService;

  @override
  Stream<List<NotificationModel>> listenToNotifications(String uid, {int limitCount = 50}) {
    return _notificationService.streamNotifications(uid, limitCount: limitCount).map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    }).handleError((e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    });
  }

  @override
  Future<void> sendNotification(String uid, NotificationModel notification) async {
    try {
      await _notificationService.addNotification(uid, notification.toFirestore());
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> markAsRead(String uid, String notificationId) async {
    try {
      await _notificationService.markAsRead(uid, notificationId);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> deleteNotification(String uid, String notificationId) async {
    try {
      await _notificationService.deleteNotification(uid, notificationId);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> markAllAsRead(String uid) async {
    try {
      await _notificationService.markAllAsRead(uid);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> clearNotifications(String uid) async {
    try {
      await _notificationService.clearNotifications(uid);
    } catch (e) {
      throw Exception(_mapErrorToUserFriendlyMessage(e));
    }
  }

  @override
  Future<void> sendLocalTestNotification() async {
    await _notificationService.sendTestNotification();
  }

  @override
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationService.showLocalNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
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

    return 'Terjadi kesalahan sistem saat mengakses data notifikasi: $error';
  }
}
