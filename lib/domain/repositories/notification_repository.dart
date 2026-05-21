import '../../models/notification_model.dart';

abstract class NotificationRepository {
  /// Listens to real-time updates for user notifications.
  Stream<List<NotificationModel>> listenToNotifications(String uid, {int limitCount = 50});

  /// Sends a new notification.
  Future<void> sendNotification(String uid, NotificationModel notification);

  /// Marks a specific notification as read.
  Future<void> markAsRead(String uid, String notificationId);

  /// Deletes a specific notification.
  Future<void> deleteNotification(String uid, String notificationId);

  /// Marks all notifications for a user as read.
  Future<void> markAllAsRead(String uid);

  /// Clears/deletes all notifications for a user.
  Future<void> clearNotifications(String uid);
}
