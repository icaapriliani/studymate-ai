import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Services & Repositories
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/gemini_service.dart';
import 'repositories/auth_repository_impl.dart';
import 'repositories/gemini_repository_impl.dart';
import 'repositories/chat_repository_impl.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/theme_provider.dart';

// Constants & Themes
import 'constants/app_theme.dart';

// Services & Repositories additions
import 'services/activity_service.dart';
import 'repositories/activity_repository_impl.dart';

import 'services/firestore_quiz_service.dart';
import 'repositories/quiz_repository_impl.dart';
import 'providers/quiz_provider.dart';

import 'services/notification_service.dart';
import 'repositories/notification_repository_impl.dart';
import 'providers/notification_provider.dart';

import 'services/learning_service.dart';
import 'repositories/learning_repository_impl.dart';
import 'providers/learning_provider.dart';

// Screens
import 'screens/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[StudyMate AI Main] Berhasil memuat file .env');
  } catch (e) {
    debugPrint('[StudyMate AI Main] GAGAL memuat file .env: $e');
  }
  
  // Initialize Firebase using the google-services.json context
  await Firebase.initializeApp();

  // Load SharedPreferences and initialize ThemeProvider at startup for 0 flicker
  final prefs = await SharedPreferences.getInstance();
  final themeProvider = ThemeProvider(prefs);
  
  runApp(StudyMateAI(themeProvider: themeProvider));
}

class StudyMateAI extends StatelessWidget {
  final ThemeProvider themeProvider;

  const StudyMateAI({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Instantiate services (Data Layer Sources)
    final authService = FirebaseAuthService();
    final firestoreService = FirestoreService();
    final geminiService = GeminiService();
    final activityService = ActivityService();
    final firestoreQuizService = FirestoreQuizService();
    final notificationService = NotificationService();
    final learningService = LearningService();

    // Instantiate repositories (Data Layer Orchestrator)
    final authRepository = AuthRepositoryImpl(
      authService: authService,
      firestoreService: firestoreService,
    );
    final geminiRepository = GeminiRepositoryImpl(
      geminiService: geminiService,
    );
    final chatRepository = ChatRepositoryImpl(
      firestoreService: firestoreService,
    );
    final activityRepository = ActivityRepositoryImpl(
      activityService: activityService,
    );
    final quizRepository = QuizRepositoryImpl(
      firestoreQuizService: firestoreQuizService,
    );
    final notificationRepository = NotificationRepositoryImpl(
      notificationService: notificationService,
    );
    final learningRepository = LearningRepositoryImpl(
      learningService: learningService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository: authRepository)..checkCurrentUser(),
        ),
        ChangeNotifierProvider<AIChatProvider>(
          create: (_) => AIChatProvider(
            geminiRepository: geminiRepository,
            chatRepository: chatRepository,
          ),
        ),
        ChangeNotifierProvider<StatisticsProvider>(
          create: (_) => StatisticsProvider(
            activityRepository: activityRepository,
            chatRepository: chatRepository,
            quizRepository: quizRepository,
          ),
        ),
        ChangeNotifierProvider<QuizProvider>(
          create: (_) => QuizProvider(
            quizRepository: quizRepository,
            geminiRepository: geminiRepository,
            notificationRepository: notificationRepository,
          ),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(
            notificationRepository: notificationRepository,
          ),
        ),
        ChangeNotifierProvider<LearningProvider>(
          create: (_) => LearningProvider(
            learningRepository: learningRepository,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'StudyMate AI',
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}