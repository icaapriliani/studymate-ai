import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bgGradientStart;
  final Color bgGradientEnd;
  final Color primaryGradientStart;
  final Color primaryGradientEnd;
  final Color textPrimary;
  final Color textSecondary;
  final Color textLight;
  final Color glassBg;
  final Color glassBorder;
  final Color glassShadow;
  final Color progressTrack;
  final Color cardBg;

  const AppThemeColors({
    required this.bgGradientStart,
    required this.bgGradientEnd,
    required this.primaryGradientStart,
    required this.primaryGradientEnd,
    required this.textPrimary,
    required this.textSecondary,
    required this.textLight,
    required this.glassBg,
    required this.glassBorder,
    required this.glassShadow,
    required this.progressTrack,
    required this.cardBg,
  });

  @override
  AppThemeColors copyWith({
    Color? bgGradientStart,
    Color? bgGradientEnd,
    Color? primaryGradientStart,
    Color? primaryGradientEnd,
    Color? textPrimary,
    Color? textSecondary,
    Color? textLight,
    Color? glassBg,
    Color? glassBorder,
    Color? glassShadow,
    Color? progressTrack,
    Color? cardBg,
  }) {
    return AppThemeColors(
      bgGradientStart: bgGradientStart ?? this.bgGradientStart,
      bgGradientEnd: bgGradientEnd ?? this.bgGradientEnd,
      primaryGradientStart: primaryGradientStart ?? this.primaryGradientStart,
      primaryGradientEnd: primaryGradientEnd ?? this.primaryGradientEnd,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textLight: textLight ?? this.textLight,
      glassBg: glassBg ?? this.glassBg,
      glassBorder: glassBorder ?? this.glassBorder,
      glassShadow: glassShadow ?? this.glassShadow,
      progressTrack: progressTrack ?? this.progressTrack,
      cardBg: cardBg ?? this.cardBg,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bgGradientStart: Color.lerp(bgGradientStart, other.bgGradientStart, t)!,
      bgGradientEnd: Color.lerp(bgGradientEnd, other.bgGradientEnd, t)!,
      primaryGradientStart: Color.lerp(primaryGradientStart, other.primaryGradientStart, t)!,
      primaryGradientEnd: Color.lerp(primaryGradientEnd, other.primaryGradientEnd, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      glassBg: Color.lerp(glassBg, other.glassBg, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E58C1),
      brightness: Brightness.light,
      primary: const Color(0xFF1E58C1),
      secondary: const Color(0xFF6B3BC7),
      surface: Colors.white,
      background: const Color(0xFFF4F6F9),
      error: Colors.redAccent,
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6F9),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    extensions: [
      lightColors,
    ],
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E58C1),
      brightness: Brightness.dark,
      primary: const Color(0xFF3B82F6), // Brighter royal blue for dark mode readability
      secondary: const Color(0xFF8B5CF6), // Brighter violet for dark mode readability
      surface: const Color(0xFF1C1E2A), // Premium soft dark slate card/surface background
      background: const Color(0xFF0F131E), // Sleek deep navy canvas background
      onSurface: const Color(0xFFF8FAFC),
      error: Colors.redAccent,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F131E),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1E2A),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF121420),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    extensions: [
      darkColors,
    ],
  );

  static const lightColors = AppThemeColors(
    bgGradientStart: Color(0xFFE2EDF9),
    bgGradientEnd: Color(0xFFEDE4F9),
    primaryGradientStart: Color(0xFF1E58C1),
    primaryGradientEnd: Color(0xFF6B3BC7),
    textPrimary: Color(0xFF2A2E43),
    textSecondary: Color(0xFF5F6982),
    textLight: Color(0xFF7A869A),
    glassBg: Color(0x33FFFFFF),
    glassBorder: Color(0x59FFFFFF),
    glassShadow: Color(0x0D000000),
    progressTrack: Color(0xFFE2E7EE),
    cardBg: Colors.white,
  );

  static const darkColors = AppThemeColors(
    bgGradientStart: Color(0xFF0F131E),
    bgGradientEnd: Color(0xFF181324),
    primaryGradientStart: Color(0xFF3B82F6),
    primaryGradientEnd: Color(0xFF8B5CF6),
    textPrimary: Color(0xFFF8FAFC), // Off-white for high legibility
    textSecondary: Color(0xFFCBD5E1), // Muted grey for subtexts
    textLight: Color(0xFF64748B), // Soft caption grey
    glassBg: Color(0x1AFFFFFF), // 10% opaque white
    glassBorder: Color(0x26FFFFFF), // 15% opaque white
    glassShadow: Color(0x33000000), // Slightly darker shadow for separation
    progressTrack: Color(0xFF1E293B), // Slate-800 progress bar track
    cardBg: Color(0xFF1C1E2A),
  );
}
