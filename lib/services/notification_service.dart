import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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

  /// Initializes notifications: requests permissions, creates Android channel, and sets up FCM listeners.
  Future<void> initialize() async {
    // 1. Request FCM permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[StudyMate Notification] Status Izin Notifikasi FCM: ${settings.authorizationStatus}');

    // 2. Request Android 13+ local notifications permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      debugPrint('[StudyMate Notification] Izin Notifikasi Android 13+ diberikan: $granted');
    }

    // 3. Initialize Flutter Local Notifications settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[StudyMate Notification] Notifikasi diklik: ${response.payload}');
      },
    );

    // 4. Create Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'studymate_channel', // id
      'StudyMate Notifications', // name
      description: 'Saluran notifikasi penting untuk StudyMate AI.',
      importance: Importance.high,
    );

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      debugPrint('[StudyMate Notification] Channel Notifikasi Android berhasil dibuat.');
    }

    // 5. Get and print FCM Token
    try {
      String? token = await _fcm.getToken();
      debugPrint('====================================================');
      debugPrint('[StudyMate Notification] FCM TOKEN BERHASIL DIPEROLEH:');
      debugPrint('$token');
      debugPrint('====================================================');
    } catch (e) {
      debugPrint('[StudyMate Notification] Gagal mendapatkan token FCM: $e');
    }

    // 6. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[StudyMate Notification] Pesan masuk di foreground: ${message.messageId}');
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 7. Handle when app is opened via notification click (FCM side)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[StudyMate Notification] Aplikasi dibuka dari notifikasi: ${message.messageId}');
    });

    // 8. Reactive listener to save FCM Token to Firestore when user logs in
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          String? token = await _fcm.getToken();
          if (token != null) {
            await saveTokenToFirestore(user.uid, token);
          }
        } catch (e) {
          debugPrint('[StudyMate Notification] Gagal mendapatkan token saat masuk log: $e');
        }
      }
    });
  }

  /// Saves FCM Token to Firestore under the user's document.
  Future<void> saveTokenToFirestore(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[StudyMate Notification] Token FCM berhasil disimpan ke Firestore untuk UID: $uid');
    } catch (e) {
      debugPrint('[StudyMate Notification] Gagal menyimpan Token FCM ke Firestore: $e');
    }
  }

  /// Sends a local notification to test local notification functionality.
  Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'studymate_channel',
      'StudyMate Notifications',
      channelDescription: 'Saluran notifikasi penting untuk StudyMate AI.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      id: 999,
      title: '📚 Pengingat Belajar',
      body: 'Jangan lupa melanjutkan materi hari ini.',
      notificationDetails: platformChannelSpecifics,
      payload: 'test_payload',
    );
    debugPrint('[StudyMate Notification] Notifikasi lokal pengujian berhasil dikirim.');
  }

  /// Displays a local notification on the status bar dynamically.
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'studymate_channel',
      'StudyMate Notifications',
      channelDescription: 'Saluran notifikasi penting untuk StudyMate AI.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
    debugPrint('[StudyMate Notification] Notifikasi status bar berhasil ditampilkan: "$title"');
  }
}
