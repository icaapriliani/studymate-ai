import '../domain/repositories/quiz_repository.dart';
import '../models/quiz_session_model.dart';
import '../models/quiz_question_model.dart';
import '../services/firestore_quiz_service.dart';

class QuizRepositoryImpl implements QuizRepository {
  final FirestoreQuizService _firestoreQuizService;

  QuizRepositoryImpl({
    required FirestoreQuizService firestoreQuizService,
  }) : _firestoreQuizService = firestoreQuizService;

  @override
  Future<List<QuizSessionModel>> getUserQuizSessions(String uid) async {
    return await _firestoreQuizService.getUserQuizSessions(uid);
  }

  @override
  Future<List<QuizQuestionModel>> getQuizQuestions(String sessionId) async {
    return await _firestoreQuizService.getQuizQuestions(sessionId);
  }

  @override
  Future<bool> canGenerateNewSession() async {
    return await _firestoreQuizService.canGenerateNewSession();
  }

  @override
  Future<void> createQuizSession(QuizSessionModel session, List<QuizQuestionModel> questions) async {
    return await _firestoreQuizService.createQuizSession(session, questions);
  }

  @override
  Future<void> submitQuizSession(QuizSessionModel session, List<QuizQuestionModel> questions) async {
    return await _firestoreQuizService.submitQuizSession(session, questions);
  }
}
