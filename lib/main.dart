import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

// Services & Repositories additions
import 'services/activity_service.dart';
import 'repositories/activity_repository_impl.dart';

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
  
  runApp(const StudyMateAI());
}

class StudyMateAI extends StatelessWidget {
  const StudyMateAI({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate services (Data Layer Sources)
    final authService = FirebaseAuthService();
    final firestoreService = FirestoreService();
    final geminiService = GeminiService();
    final activityService = ActivityService();

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

    return MultiProvider(
      providers: [
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
          ),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'StudyMate AI',
        home: SplashPage(),
      ),
    );
  }
}