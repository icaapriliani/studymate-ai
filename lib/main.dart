import 'package:flutter/material.dart';
import 'screens/splash/splash_page.dart';

void main() {
  runApp(const StudyMateAI());
}

class StudyMateAI extends StatelessWidget {
  const StudyMateAI({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyMate AI',
      home: SplashPage(),
    );
  }
}