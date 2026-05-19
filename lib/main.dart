import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Services & Repositories
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'repositories/auth_repository_impl.dart';

// Providers
import 'providers/auth_provider.dart';

// Screens
import 'screens/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

    // Instantiate repository (Data Layer Orchestrator)
    final authRepository = AuthRepositoryImpl(
      authService: authService,
      firestoreService: firestoreService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository: authRepository)..checkCurrentUser(),
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