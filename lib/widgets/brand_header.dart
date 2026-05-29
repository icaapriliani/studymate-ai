import 'package:flutter/material.dart';
import '../utils/theme_context.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.logoWidth = 220, this.showTitle = true});

  final double logoWidth;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium high-contrast colors
    final Color studyColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E58C1);
    final Color mateColor = isDark ? const Color(0xFFC084FC) : const Color(0xFF6B3BC7);
    final Color aiColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD9A05B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium brand icon with rounded circle container and high-tech glow
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x1F3B82F6) : const Color(0x0F1E58C1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0x333B82F6) : const Color(0x1A1E58C1),
              width: 1.5,
            ),
          ),
          child: Image.asset(
            'assets/branding/studymate_logo_full_transparent.png',
            width: logoWidth > 120 ? 90 : logoWidth,
            height: logoWidth > 120 ? 90 : logoWidth,
            fit: BoxFit.contain,
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 16),
          // Dynamic theme-adaptive RichText
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 30,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Study',
                  style: TextStyle(
                    color: studyColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'Mate ',
                  style: TextStyle(
                    color: mateColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(
                    color: aiColor,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: isDark ? const Color(0x66FBBF24) : const Color(0x33D9A05B),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Smart AI Learning Companion',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
