import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/activity_repository.dart';
import '../models/activity_model.dart';
import '../models/conversation_model.dart';
import '../domain/repositories/quiz_repository.dart';
import '../models/quiz_session_model.dart';
import '../models/learning_target_model.dart';

class StatisticsProvider extends ChangeNotifier {
  final ActivityRepository _activityRepository;
  final ChatRepository _chatRepository;
  final QuizRepository _quizRepository;

  StatisticsProvider({
    required ActivityRepository activityRepository,
    required ChatRepository chatRepository,
    required QuizRepository quizRepository,
  })  : _activityRepository = activityRepository,
        _chatRepository = chatRepository,
        _quizRepository = quizRepository;

  List<ActivityModel> _activities = [];
  List<ConversationModel> _conversations = [];
  List<QuizSessionModel> _quizResults = [];
  LearningTargetModel? _learningTarget;

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _activitiesSubscription;
  StreamSubscription? _quizzesSubscription;
  StreamSubscription? _targetSubscription;

  List<ActivityModel> get activities => _activities;
  List<ConversationModel> get conversations => _conversations;
  List<QuizSessionModel> get quizResults => _quizResults;
  LearningTargetModel? get learningTarget => _learningTarget;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Real-time calculated properties
  int get totalConversations => _conversations.length;
  int get totalMateriDibuka => _activities.where((a) => a.type == 'material').length;
  int get totalPesan => _activities.where((a) => a.type == 'chat').length * 2; // User + AI messages
  int get totalQuizTaken => _quizResults.where((q) => q.completed).length;

  int get weeklyQuizTarget => _learningTarget?.weeklyQuizTarget ?? 5;

  int get quizzesCompletedThisWeek {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _quizResults.where((q) {
      return q.completed && q.createdAt.isAfter(startOfWeek) && q.createdAt.isBefore(endOfWeek);
    }).length;
  }

  int get averageQuizScore {
    final completedQuizzes = _quizResults.where((q) => q.completed).toList();
    if (completedQuizzes.isEmpty) return 0;
    int totalScore = completedQuizzes.fold(0, (sum, item) => sum + item.score);
    return (totalScore / completedQuizzes.length).round();
  }

  int get totalAIChats {
    return _activities.where((a) => a.type == 'chat').length;
  }

  int get learningProgressPercentage {
    final target = weeklyQuizTarget;
    if (target <= 0) return 0;
    return ((quizzesCompletedThisWeek / target) * 100).clamp(0, 100).round();
  }

  int get learningStreak {
    final Set<DateTime> activeDates = {};

    for (final activity in _activities) {
      final date = DateTime(activity.timestamp.year, activity.timestamp.month, activity.timestamp.day);
      activeDates.add(date);
    }

    for (final quiz in _quizResults) {
      final date = DateTime(quiz.createdAt.year, quiz.createdAt.month, quiz.createdAt.day);
      activeDates.add(date);
    }

    if (activeDates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int streak = 0;
    DateTime checkDate = today;

    // If there was no activity today, check if there was activity yesterday.
    // If not even yesterday, streak is broken.
    if (!activeDates.contains(today)) {
      if (activeDates.contains(yesterday)) {
        checkDate = yesterday;
      } else {
        return 0;
      }
    }

    // Count backwards consecutively
    while (activeDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

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

  /// Updates the user's weekly quiz target in Firestore.
  Future<void> updateWeeklyTarget(String uid, int target) async {
    if (uid.isEmpty) return;
    try {
      await _quizRepository.updateLearningTarget(uid, target);
      debugPrint('[StatisticsProvider] Berhasil memperbarui target mingguan menjadi $target');
    } catch (e) {
      debugPrint('[StatisticsProvider] Gagal memperbarui target mingguan: $e');
      _errorMessage = 'Gagal memperbarui target: ${e.toString().replaceFirst('Exception: ', '')}';
      notifyListeners();
    }
  }

  /// Listens to real-time activities, quiz sessions, and learning targets from Firestore.
  void initStatistics(String uid) {
    if (uid.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;

    // Cancel old subscriptions
    _activitiesSubscription?.cancel();
    _quizzesSubscription?.cancel();
    _targetSubscription?.cancel();

    // 1. Fetch conversations asynchronously
    _chatRepository.getConversations(uid).then((convList) {
      _conversations = convList;
      notifyListeners();
    }).catchError((e) {
      debugPrint('[StatisticsProvider] Gagal memuat percakapan: $e');
      _errorMessage = 'Gagal memuat obrolan: ${e.toString().replaceFirst('Exception: ', '')}';
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
        _errorMessage = 'Gagal sinkronisasi aktivitas: ${error.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
        notifyListeners();
      },
    );

    // 3. Subscribe to real-time quiz sessions stream
    _quizzesSubscription = _quizRepository.listenToUserQuizSessions(uid).listen(
      (quizList) {
        _quizResults = quizList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[StatisticsProvider] Error pada aliran kuis: $error');
        _errorMessage = 'Gagal sinkronisasi kuis: ${error.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
        notifyListeners();
      },
    );

    // 4. Subscribe to real-time learning target stream
    _targetSubscription = _quizRepository.listenToLearningTarget(uid).listen(
      (target) {
        _learningTarget = target;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[StatisticsProvider] Error pada aliran target belajar: $error');
        _errorMessage = 'Gagal sinkronisasi target belajar: ${error.toString().replaceFirst('Exception: ', '')}';
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
      _quizResults = await _quizRepository.getUserQuizSessions(uid);
    } catch (e) {
      _errorMessage = 'Gagal memuat ulang data: ${e.toString().replaceFirst('Exception: ', '')}';
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
    _quizzesSubscription?.cancel();
    _targetSubscription?.cancel();
    super.dispose();
  }
}
