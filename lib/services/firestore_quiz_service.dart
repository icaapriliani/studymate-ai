import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_session_model.dart';
import '../models/quiz_question_model.dart';
import '../models/learning_target_model.dart';

class FirestoreQuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches all quiz sessions for a user
  Future<List<QuizSessionModel>> getUserQuizSessions(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('quiz_sessions')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return QuizSessionModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load quiz sessions: $e');
    }
  }

  /// Fetches questions for a specific quiz session
  Future<List<QuizQuestionModel>> getQuizQuestions(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User is not logged in.');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quiz_sessions')
          .doc(sessionId)
          .collection('questions')
          .get();

      return querySnapshot.docs.map((doc) {
        return QuizQuestionModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load quiz questions: $e');
    }
  }

  /// Checks if the user can generate a new quiz today (Limit: 5/day)
  Future<bool> canGenerateNewSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User is not logged in.');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quiz_sessions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return querySnapshot.docs.length < 5;
    } catch (e) {
      throw Exception('Failed to check generation limit: $e');
    }
  }

  /// Saves a new quiz session along with its questions
  Future<void> createQuizSession(QuizSessionModel session, List<QuizQuestionModel> questions) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User is not logged in.');

      final batch = _firestore.batch();
      
      final sessionRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quiz_sessions')
          .doc(session.id);
          
      batch.set(sessionRef, session.toFirestore());

      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final questionRef = sessionRef.collection('questions').doc('q_$i');
        batch.set(questionRef, q.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create quiz session: $e');
    }
  }

  /// Updates an existing quiz session and its user answers
  Future<void> submitQuizSession(QuizSessionModel session, List<QuizQuestionModel> questions) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User is not logged in.');

      final batch = _firestore.batch();
      
      final sessionRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quiz_sessions')
          .doc(session.id);
          
      batch.update(sessionRef, {
        'completed': session.completed,
        'score': session.score,
        'aiFeedback': session.aiFeedback,
      });

      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final questionRef = sessionRef.collection('questions').doc(q.id.isEmpty ? 'q_$i' : q.id);
        batch.update(questionRef, {
          'userAnswer': q.userAnswer,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to submit quiz session: $e');
    }
  }

  /// Listens to quiz sessions real-time stream
  Stream<List<QuizSessionModel>> listenToUserQuizSessions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('quiz_sessions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return QuizSessionModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Listens to learning target real-time stream
  Stream<LearningTargetModel> listenToLearningTarget(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('learning_target')
        .doc('target_doc')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return LearningTargetModel.fromFirestore(snapshot.data()!);
      }
      return LearningTargetModel.defaultTarget();
    });
  }

  /// Saves or updates the user's learning target
  Future<void> updateLearningTarget(String uid, int target) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('learning_target')
          .doc('target_doc')
          .set({
        'weeklyQuizTarget': target,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update learning target: $e');
    }
  }
}
