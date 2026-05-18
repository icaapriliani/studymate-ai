import 'dart:ui';
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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.bgGradientStart,
              AppColors.bgGradientEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 48.0 : 24.0,
                        vertical: 20.0,
                      ),
                      child: AnimatedOpacity(
                        opacity: _startAnimation ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 30.0,
                            end: _startAnimation ? 0.0 : 30.0,
                          ),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, slideValue, child) {
                            return Transform.translate(
                              offset: Offset(0, slideValue),
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Spacer
                              const Spacer(flex: 3),

                              // 1. Glassmorphism Card with Custom Vector AI Logo
                              Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.glassShadow,
                                        blurRadius: 35,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(36),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 20.0,
                                        sigmaY: 20.0,
                                      ),
                                      child: Container(
                                        width: isTablet ? 160 : 136,
                                        height: isTablet ? 160 : 136,
                                        decoration: BoxDecoration(
                                          color: AppColors.glassBg,
                                          borderRadius: BorderRadius.circular(36),
                                          border: Border.all(
                                            color: AppColors.glassBorder,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: isTablet ? 72 : 56,
                                            height: isTablet ? 72 : 56,
                                            child: CustomPaint(
                                              painter: AILogoPainter(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(flex: 2),

                              // 2. Titles (StudyMate AI & Subtitle)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Gradient Text for "StudyMate AI"
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [
                                        AppColors.primaryGradientStart,
                                        AppColors.primaryGradientEnd,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                    child: Text(
                                      'StudyMate AI',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isTablet ? 42 : 34,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Subtitle
                                  Text(
                                    'Elevating your learning with AI',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 15,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(flex: 2),

                              // 3. Loading Bar & Initialization Status
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 3000),
                                curve: Curves.easeInOutQuart,
                                builder: (context, progressValue, child) {
                                  return SizedBox(
                                    width: isTablet ? 280 : 210,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Capsule Progress Bar
                                        Container(
                                          height: 6,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: AppColors.progressTrack,
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            child: ShaderMask(
                                              shaderCallback: (bounds) =>
                                                  const LinearGradient(
                                                colors: [
                                                  AppColors
                                                      .primaryGradientStart,
                                                  AppColors.primaryGradientEnd,
                                                ],
                                              ).createShader(bounds),
                                              child: LinearProgressIndicator(
                                                value: progressValue,
                                                backgroundColor:
                                                    Colors.transparent,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Status text
                                        Text(
                                          'INITIALIZING TUTOR',
                                          style: TextStyle(
                                            fontSize: isTablet ? 12 : 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const Spacer(flex: 3),

                              // 4. Bottom Branding/Academic Engine
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_outlined,
                                        size: isTablet ? 16 : 13,
                                        color: AppColors.textLight,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ACADEMIC EXCELLENCE ENGINE',
                                        style: TextStyle(
                                          fontSize: isTablet ? 11 : 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Subtle aesthetic dot
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.textLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ],
                          ),
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
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}

/// A custom-painted modern AI logo shape
class AILogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    // Draw stylized AI petal/crescent node matching the mockup's futuristic style
    // 1. Center Floating Droplet / Diamond
    final centerPath = Path();
    centerPath.moveTo(w * 0.5, h * 0.28);
    centerPath.cubicTo(w * 0.56, h * 0.35, w * 0.56, h * 0.40, w * 0.5, h * 0.46);
    centerPath.cubicTo(w * 0.44, h * 0.40, w * 0.44, h * 0.35, w * 0.5, h * 0.28);
    centerPath.close();
    canvas.drawPath(centerPath, paint);

    // 2. Left Sleek Petal Shape
    final leftPath = Path();
    leftPath.moveTo(w * 0.45, h * 0.48);
    leftPath.cubicTo(w * 0.28, h * 0.45, w * 0.20, h * 0.28, w * 0.22, h * 0.18);
    leftPath.cubicTo(w * 0.30, h * 0.16, w * 0.40, h * 0.30, w * 0.45, h * 0.45);
    leftPath.close();
    canvas.drawPath(leftPath, paint);

    // 3. Right Sleek Petal Shape
    final rightPath = Path();
    rightPath.moveTo(w * 0.55, h * 0.48);
    rightPath.cubicTo(w * 0.72, h * 0.45, w * 0.80, h * 0.28, w * 0.78, h * 0.18);
    rightPath.cubicTo(w * 0.70, h * 0.16, w * 0.60, h * 0.30, w * 0.55, h * 0.45);
    rightPath.close();
    canvas.drawPath(rightPath, paint);

    // 4. Bottom Support Crescent / Digital Wings
    final bottomPath = Path();
    bottomPath.moveTo(w * 0.24, h * 0.58);
    bottomPath.quadraticBezierTo(w * 0.5, h * 0.80, w * 0.76, h * 0.58);
    bottomPath.quadraticBezierTo(w * 0.5, h * 0.68, w * 0.24, h * 0.58);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


