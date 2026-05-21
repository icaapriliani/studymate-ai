import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository;

  NotificationProvider({required NotificationRepository notificationRepository})
      : _notificationRepository = notificationRepository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((NotificationModel n) => !n.isRead).length;

  /// Initializes real-time notifications for the given user.
  void initNotifications(String uid) {
    if (uid.isEmpty) {
      _notifications = [];
      _subscription?.cancel();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    _subscription?.cancel();
    _subscription = _notificationRepository.listenToNotifications(uid).listen(
      (list) {
        _notifications = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[NotificationProvider] Error in notification stream: $error');
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Sends/adds a new notification to Firestore.
  Future<void> sendNotification({
    required String uid,
    required String title,
    required String message,
    required String type,
  }) async {
    if (uid.isEmpty) return;

    try {
      final notification = NotificationModel(
        id: '',
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _notificationRepository.sendNotification(uid, notification);
      debugPrint('[NotificationProvider] Berhasil mengirim notifikasi "$type": "$title"');
    } catch (e) {
      debugPrint('[NotificationProvider] Gagal mengirim notifikasi: $e');
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String uid, String notificationId) async {
    if (uid.isEmpty || notificationId.isEmpty) return;
    try {
      await _notificationRepository.markAsRead(uid, notificationId);
    } catch (e) {
      debugPrint('[NotificationProvider] Gagal menandai dibaca: $e');
    }
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(String uid, String notificationId) async {
    if (uid.isEmpty || notificationId.isEmpty) return;
    try {
      await _notificationRepository.deleteNotification(uid, notificationId);
    } catch (e) {
      debugPrint('[NotificationProvider] Gagal menghapus notifikasi tunggal: $e');
    }
  }

  /// Marks all notifications for a user as read.
  Future<void> markAllAsRead(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _notificationRepository.markAllAsRead(uid);
    } catch (e) {
      debugPrint('[NotificationProvider] Gagal menandai semua dibaca: $e');
    }
  }

  /// Clears/deletes all notifications for a user.
  Future<void> clearNotifications(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _notificationRepository.clearNotifications(uid);
    } catch (e) {
      debugPrint('[NotificationProvider] Gagal menghapus notifikasi: $e');
    }
  }

  /// Explicitly cancels stream subscription on logout/switch account.
  void cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
