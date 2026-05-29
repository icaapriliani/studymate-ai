import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../auth/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    // Trigger the entrance animation after a microsecond delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _startAnimation = true;
        });
      }
    });

    // Automatically transition to LoginPage after 3 seconds of loading animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: AnimatedOpacity(
                  opacity: _startAnimation ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.easeOutCubic,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.92,
                      end: _startAnimation ? 1.0 : 0.92,
                    ),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, scaleValue, child) {
                      return Transform.scale(scale: scaleValue, child: child);
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0x0F1E58C1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0x1A1E58C1),
                                  width: 1.5,
                                ),
                              ),
                              child: Image.asset(
                                'assets/branding/studymate_splash_icon.png',
                                width: 96,
                                height: 96,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 22),
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 32,
                                  letterSpacing: -0.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Study',
                                    style: TextStyle(
                                      color: Color(0xFF1E58C1),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Mate ',
                                    style: TextStyle(
                                      color: Color(0xFF6B3BC7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'AI',
                                    style: TextStyle(
                                      color: Color(0xFFD9A05B),
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Color(0x33D9A05B),
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Smart AI Learning Companion',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1E58C1),
                                ),
                                backgroundColor: Color(0x1F6B3BC7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToNextScreen() {
    // When initialization completes, transition smoothly to the Login/Home page
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}
