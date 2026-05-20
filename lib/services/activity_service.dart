import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityService {
  final FirebaseFirestore _firestore;

  ActivityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _activitiesCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('activities');

  /// Saves a new user activity document.
  Future<void> saveActivity(String uid, String type, String title, DateTime timestamp) async {
    try {
      await _activitiesCollection(uid).add({
        'type': type,
        'title': title,
        'timestamp': Timestamp.fromDate(timestamp),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Returns a Stream of all user activities ordered by timestamp descending.
  Stream<List<Map<String, dynamic>>> listenToActivities(String uid) {
    return _activitiesCollection(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Fallback async getter for all activities.
  Future<List<Map<String, dynamic>>> getActivities(String uid) async {
    try {
      final snapshot = await _activitiesCollection(uid)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
