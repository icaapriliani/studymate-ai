import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference for User's Notifications
  CollectionReference<Map<String, dynamic>> _notificationsCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  /// Streams notifications for a specific user, ordered by createdAt descending.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications(String uid, {int limitCount = 50}) {
    return _notificationsCollection(uid)
        .orderBy('createdAt', descending: true)
        .limit(limitCount)
        .snapshots();
  }

  /// Adds a new notification document to Firestore.
  Future<void> addNotification(String uid, Map<String, dynamic> data) async {
    try {
      await _notificationsCollection(uid).add(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String uid, String notificationId) async {
    try {
      await _notificationsCollection(uid).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a specific notification document.
  Future<void> deleteNotification(String uid, String notificationId) async {
    try {
      await _notificationsCollection(uid).doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Marks all notifications for a user as read using a WriteBatch.
  Future<void> markAllAsRead(String uid) async {
    try {
      final snapshot = await _notificationsCollection(uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Clears/deletes all notifications for a user using a WriteBatch.
  Future<void> clearNotifications(String uid) async {
    try {
      final snapshot = await _notificationsCollection(uid).get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
