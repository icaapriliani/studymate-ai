import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/activity_repository.dart';
import '../models/activity_model.dart';
import '../models/conversation_model.dart';

class StatisticsProvider extends ChangeNotifier {
  final ActivityRepository _activityRepository;
  final ChatRepository _chatRepository;

  StatisticsProvider({
    required ActivityRepository activityRepository,
    required ChatRepository chatRepository,
  })  : _activityRepository = activityRepository,
        _chatRepository = chatRepository;

  List<ActivityModel> _activities = [];
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _activitiesSubscription;

  List<ActivityModel> get activities => _activities;
  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Real-time calculated properties
  int get totalConversations => _conversations.length;
  int get totalMateriDibuka => _activities.where((a) => a.type == 'material').length;
  int get totalPesan => _activities.where((a) => a.type == 'chat').length * 2; // User + AI messages

  /// Saves a new user activity dynamically (chat or material).
  Future<void> saveActivity(String uid, String type, String title) async {
    if (uid.isEmpty) return;
    try {
      await _activityRepository.saveActivity(uid, type, title, DateTime.now());
      debugPrint('[StatisticsProvider] Berhasil menyimpan aktivitas "$type" dengan judul "$title"');
    } catch (e) {
      debugPrint('[StatisticsProvider] Gagal menyimpan aktivitas: $e');
    }
  }

  /// Listens to real-time activities and loads conversations from Firestore.
  void initStatistics(String uid) {
    if (uid.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    // Do not notifyListeners() during build sequence

    _activitiesSubscription?.cancel();

    // 1. Fetch conversations asynchronously
    _chatRepository.getConversations(uid).then((convList) {
      _conversations = convList;
      notifyListeners();
    }).catchError((e) {
      debugPrint('[StatisticsProvider] Gagal memuat percakapan: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    });

    // 2. Subscribe to real-time activities stream
    _activitiesSubscription = _activityRepository.listenToActivities(uid).listen(
      (activityList) {
        _activities = activityList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[StatisticsProvider] Error pada aliran aktivitas: $error');
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Refreshes all statistics statically as a fallback.
  Future<void> refreshStatistics(String uid) async {
    if (uid.isEmpty) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _conversations = await _chatRepository.getConversations(uid);
      _activities = await _activityRepository.getActivities(uid);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculates weekly activity counts grouped by day of the week (Monday to Sunday) for the current week.
  List<int> getWeeklyActivityCounts() {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final endOfWeek = startOfWeek.add(const Duration(days: 7)); // Next Monday 00:00:00

    // Filter activities belonging to the current calendar week
    final weeklyActivities = _activities.where((a) {
      return a.timestamp.isAfter(startOfWeek) && a.timestamp.isBefore(endOfWeek);
    }).toList();

    final List<int> counts = List.filled(7, 0);
    for (final a in weeklyActivities) {
      // Dart's DateTime.weekday is 1 (Monday) to 7 (Sunday)
      int index = a.timestamp.weekday - 1;
      if (index >= 0 && index < 7) {
        counts[index]++;
      }
    }
    return counts;
  }

  /// Returns the sum of all activities in the current calendar week.
  int getWeeklyTotalActivities() {
    return getWeeklyActivityCounts().reduce((a, b) => a + b);
  }

  /// Private helper to get Monday of the current week (00:00:00).
  DateTime _getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    super.dispose();
  }
}
