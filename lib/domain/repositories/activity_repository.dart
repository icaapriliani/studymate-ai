import '../../models/activity_model.dart';

abstract class ActivityRepository {
  /// Saves a new user activity.
  Future<void> saveActivity(String uid, String type, String title, DateTime timestamp);

  /// Listens to real-time updates for user activities.
  Stream<List<ActivityModel>> listenToActivities(String uid);

  /// Retrieves a static list of all user activities.
  Future<List<ActivityModel>> getActivities(String uid);
}
