import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/repositories/gemini_repository.dart';
import '../domain/repositories/quiz_repository.dart';
import '../domain/repositories/notification_repository.dart';
import '../models/quiz_session_model.dart';
import '../models/quiz_question_model.dart';
import '../models/notification_model.dart';

class QuizProvider extends ChangeNotifier {
  final QuizRepository _quizRepository;
  final GeminiRepository _geminiRepository;
  final NotificationRepository _notificationRepository;

  QuizProvider({
    required QuizRepository quizRepository,
    required GeminiRepository geminiRepository,
    required NotificationRepository notificationRepository,
  })  : _quizRepository = quizRepository,
        _geminiRepository = geminiRepository,
        _notificationRepository = notificationRepository;

  List<QuizSessionModel> _sessions = [];
  List<QuizSessionModel> get sessions => _sessions;

  List<QuizQuestionModel> _currentQuestions = [];
  List<QuizQuestionModel> get currentQuestions => _currentQuestions;

  QuizSessionModel? _currentSession;
  QuizSessionModel? get currentSession => _currentSession;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Selected answers: questionId -> selected option
  Map<String, String> _selectedAnswers = {};
  Map<String, String> get selectedAnswers => _selectedAnswers;

  /// Fetch all quiz sessions for a user
  Future<void> fetchQuizSessions(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await _quizRepository.getUserQuizSessions(uid);
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar kuis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads an existing session and its questions
  Future<void> loadSession(QuizSessionModel session) async {
    _isLoading = true;
    _errorMessage = null;
    _currentSession = session;
    _currentQuestions = [];
    _selectedAnswers = {};
    notifyListeners();

    try {
      _currentQuestions = await _quizRepository.getQuizQuestions(session.id);
      for (var q in _currentQuestions) {
        if (q.userAnswer != null && q.userAnswer!.isNotEmpty) {
          _selectedAnswers[q.id] = q.userAnswer!;
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat pertanyaan kuis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates a new quiz session via AI
  Future<bool> generateNewSession(String materialId, String materialTitle) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check generation limit (5/day)
      final canGenerate = await _quizRepository.canGenerateNewSession();
      if (!canGenerate) {
        _errorMessage = 'Kamu telah mencapai batas generate quiz hari ini. Silakan coba lagi besok.';
        return false;
      }

      // 2. Request AI to generate questions & parse safely with 1x background retry
      List<QuizQuestionModel> parsedQuestions = [];
      int attempt = 0;
      const int maxAttempts = 2;

      while (attempt < maxAttempts) {
        attempt++;
        try {
          debugPrint('[QuizProvider] Percobaan $attempt: Menghubungi Gemini AI...');
          final jsonResponse = await _geminiRepository.generateQuizQuestions(materialTitle);
          parsedQuestions = _parseAIResponse(jsonResponse);
          if (parsedQuestions.isEmpty) {
            throw Exception('AI tidak menghasilkan pertanyaan yang valid.');
          }
          break; // Succeeded! Break the retry loop
        } catch (e) {
          debugPrint('[QuizProvider] Percobaan $attempt gagal: $e');
          if (attempt >= maxAttempts) {
            rethrow; // Rethrow to outer catch block if we have exhausted retries
          }
          // Log and try again
          debugPrint('[QuizProvider] Mengulangi generate kuis (retry otomatis 1x)...');
        }
      }

      // 4. Create Session Model
      final newSession = QuizSessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        materialId: materialId,
        materialTitle: materialTitle,
        createdAt: DateTime.now(),
        completed: false,
        score: 0,
        totalQuestions: parsedQuestions.length,
        aiFeedback: '',
      );

      // Give generated IDs to questions
      for (var i = 0; i < parsedQuestions.length; i++) {
        parsedQuestions[i] = parsedQuestions[i].copyWith(id: 'q_$i');
      }

      // 5. Save to Firestore
      await _quizRepository.createQuizSession(newSession, parsedQuestions);
      
      // Update local state
      _sessions.insert(0, newSession);
      _currentSession = newSession;
      _currentQuestions = parsedQuestions;
      _selectedAnswers = {};
      
      return true;
    } catch (e) {
      debugPrint('[QuizProvider] Error generateNewSession: $e');
      final cleanMessage = e.toString().replaceFirst('Exception: ', '');
      if (cleanMessage.contains('batas generate quiz')) {
        _errorMessage = cleanMessage;
      } else {
        _errorMessage = 'Gagal membuat kuis baru: $cleanMessage';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<QuizQuestionModel> _parseAIResponse(String jsonString) {
    try {
      String cleanJson = jsonString.trim();
      
      // Remove markdown code blocks if present (e.g. ```json ... ```)
      final RegExp jsonBlockRegExp = RegExp(
        r'```(?:json)?\s*([\s\S]*?)\s*```',
        caseSensitive: false,
      );
      
      final match = jsonBlockRegExp.firstMatch(cleanJson);
      if (match != null) {
        cleanJson = match.group(1) ?? cleanJson;
      }
      
      // Find JSON array bounds to strip any other surrounding text
      int startIndex = cleanJson.indexOf('[');
      int endIndex = cleanJson.lastIndexOf(']');
      
      if (startIndex == -1 || endIndex == -1) {
        throw const FormatException('Tidak menemukan format array JSON.');
      }
      
      cleanJson = cleanJson.substring(startIndex, endIndex + 1);
      
      final decoded = jsonDecode(cleanJson);
      if (decoded is! List) {
        throw const FormatException('Hasil decode JSON bukan berupa list/array.');
      }
      
      List<QuizQuestionModel> questions = [];
      for (var item in decoded) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Setiap pertanyaan kuis harus berupa objek JSON.');
        }
        
        // Validate required fields
        final question = item['question'];
        final options = item['options'];
        final correctAnswer = item['correctAnswer'];
        final explanation = item['explanation'];
        
        if (question == null || question is! String || question.trim().isEmpty) {
          throw const FormatException('Pertanyaan (question) tidak boleh kosong.');
        }
        
        if (options == null || options is! List) {
          throw const FormatException('Opsi jawaban (options) harus berupa list.');
        }
        
        // Ensure options list contains only non-empty strings and has exactly 4 choices
        List<String> optionsList = [];
        for (var opt in options) {
          if (opt == null || opt.toString().trim().isEmpty) {
            throw const FormatException('Opsi jawaban tidak boleh kosong.');
          }
          optionsList.add(opt.toString().trim());
        }
        
        if (optionsList.length != 4) {
          throw FormatException('Opsi jawaban harus memiliki tepat 4 pilihan (menemukan: ${optionsList.length}).');
        }
        
        if (correctAnswer == null || correctAnswer is! String || correctAnswer.trim().isEmpty) {
          throw const FormatException('Jawaban benar (correctAnswer) tidak boleh kosong.');
        }
        
        final cleanCorrectAnswer = correctAnswer.trim();
        
        // Hardening check: Ensure correctAnswer matches one of the options
        if (!optionsList.contains(cleanCorrectAnswer)) {
          throw FormatException(
            'Jawaban benar "$cleanCorrectAnswer" tidak cocok dengan opsi mana pun yang tersedia.'
          );
        }
        
        if (explanation == null || explanation is! String || explanation.trim().isEmpty) {
          throw const FormatException('Penjelasan (explanation) tidak boleh kosong.');
        }
        
        questions.add(QuizQuestionModel(
          id: '',
          question: question.trim(),
          options: optionsList,
          correctAnswer: cleanCorrectAnswer,
          explanation: explanation.trim(),
        ));
      }
      
      return questions;
    } catch (e) {
      debugPrint('[QuizProvider] JSON Parsing & Validation Error: $e');
      throw Exception('Format JSON tidak valid atau tidak memenuhi kriteria: $e');
    }
  }

  void selectAnswer(String questionId, String answer) {
    _selectedAnswers[questionId] = answer;
    notifyListeners();
  }

  Future<bool> submitQuizSession() async {
    if (_currentSession == null || _currentQuestions.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      int correctAnswers = 0;
      List<QuizQuestionModel> updatedQuestions = [];

      for (var q in _currentQuestions) {
        final userAnswer = _selectedAnswers[q.id] ?? '';
        updatedQuestions.add(q.copyWith(userAnswer: userAnswer));
        if (userAnswer == q.correctAnswer) {
          correctAnswers++;
        }
      }
      
      int totalQuestions = _currentQuestions.length;
      int score = ((correctAnswers / totalQuestions) * 100).round();

      // Generate AI Feedback based on score
      String prompt = '''
Kamu adalah AI Tutor di StudyMate AI. Seorang pengguna baru saja menyelesaikan kuis untuk materi "${_currentSession!.materialTitle}".
Mereka menjawab benar $correctAnswers dari $totalQuestions pertanyaan. Nilai mereka adalah $score.
Berikan feedback evaluasi belajar singkat, membangun, dan menyemangati (sekitar 2 paragraf singkat) dalam bahasa Indonesia.
''';
      String aiFeedback = await _geminiRepository.getAIResponse(prompt);

      // Update current session
      _currentSession = _currentSession!.copyWith(
        completed: true,
        score: score,
        aiFeedback: aiFeedback,
      );

      // Save to Firestore
      await _quizRepository.submitQuizSession(_currentSession!, updatedQuestions);
      
      // Refresh current session questions and list
      _currentQuestions = updatedQuestions;
      
      final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
      if (index != -1) {
        _sessions[index] = _currentSession!;
      }

      // Auto-Trigger Notifications
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          // 1. Quiz Selesai Notification
          await _notificationRepository.sendNotification(
            uid,
            NotificationModel(
              id: '',
              title: '🎉 Kuis Selesai!',
              message: 'Skor kamu mencapai $score% di kuis "${_currentSession!.materialTitle}".',
              type: NotificationModel.typeQuizCompleted,
              isRead: false,
              createdAt: DateTime.now(),
            ),
          );

          // 2. AI Feedback Positif (Skor >= 80)
          if (score >= 80) {
            await _notificationRepository.sendNotification(
              uid,
              NotificationModel(
                id: '',
                title: '✨ Feedback AI Positif!',
                message: 'Kinerja luar biasa! Skor kamu $score%. Tutor AI sangat terkesan.',
                type: NotificationModel.typeAiFeedback,
                isRead: false,
                createdAt: DateTime.now(),
              ),
            );
          }

          // 3. Target Belajar Tercapai
          final sessionsList = await _quizRepository.getUserQuizSessions(uid);
          final targetDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('learning_target')
              .doc('target_doc')
              .get();
              
          int target = 5; // default target
          if (targetDoc.exists && targetDoc.data() != null) {
            target = targetDoc.data()!['weeklyQuizTarget'] as int? ?? 5;
          }

          final now = DateTime.now();
          int daysToSubtract = now.weekday - 1;
          final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));

          final completedThisWeek = sessionsList.where((q) {
            return q.completed && q.createdAt.isAfter(startOfWeek) && q.createdAt.isBefore(endOfWeek);
          }).length;

          if (completedThisWeek == target) {
            await _notificationRepository.sendNotification(
              uid,
              NotificationModel(
                id: '',
                title: '🎯 Target Tercapai!',
                message: 'Luar biasa! Target belajar mingguan tercapai ($target kuis diselesaikan).',
                type: NotificationModel.typeLearningTarget,
                isRead: false,
                createdAt: DateTime.now(),
              ),
            );
          }
        }
      } catch (notifErr) {
        debugPrint('[QuizProvider] Gagal memproses auto-trigger notifikasi: $notifErr');
      }

      return true;
    } catch (e) {
      debugPrint('[QuizProvider] Error submitQuizSession: $e');
      _errorMessage = 'Gagal mengirim kuis: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
