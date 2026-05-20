import '../../models/quiz_session_model.dart';
import '../../models/quiz_question_model.dart';
import '../../models/learning_target_model.dart';

abstract class QuizRepository {
  /// Fetches all quiz sessions for a user.
  Future<List<QuizSessionModel>> getUserQuizSessions(String uid);

  /// Fetches questions for a specific quiz session
  Future<List<QuizQuestionModel>> getQuizQuestions(String sessionId);

  /// Checks if the user can generate a new quiz today (Limit: 5/day)
  Future<bool> canGenerateNewSession();

  /// Saves a new quiz session along with its questions
  Future<void> createQuizSession(QuizSessionModel session, List<QuizQuestionModel> questions);

  /// Updates an existing quiz session and its user answers
  Future<void> submitQuizSession(QuizSessionModel session, List<QuizQuestionModel> questions);

  /// Listens to real-time updates for quiz sessions.
  Stream<List<QuizSessionModel>> listenToUserQuizSessions(String uid);

  /// Listens to real-time updates for the learning target.
  Stream<LearningTargetModel> listenToLearningTarget(String uid);

  /// Updates the user's learning target in Firestore.
  Future<void> updateLearningTarget(String uid, int target);
}
