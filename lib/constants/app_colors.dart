import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background Pastel Gradient Colors
  static const Color bgGradientStart = Color(0xFFE2EDF9); // Light Pastel Blue
  static const Color bgGradientEnd = Color(0xFFEDE4F9);   // Soft Pastel Purple

  // Primary Action / Brand Gradient Colors
  static const Color primaryGradientStart = Color(0xFF1E58C1); // Royal Indigo-Blue
  static const Color primaryGradientEnd = Color(0xFF6B3BC7);   // Vivid Violet-Purple

  // Text Colors
  static const Color textPrimary = Color(0xFF2A2E43);   // Deep slate
  static const Color textSecondary = Color(0xFF5F6982); // Muted slate-grey
  static const Color textLight = Color(0xFF7A869A);     // Lighter grey for small captions

  // Glassmorphism Card Style
  static const Color glassBg = Color(0x33FFFFFF);       // 20% transparent white
  static const Color glassBorder = Color(0x59FFFFFF);   // 35% transparent white
  static const Color glassShadow = Color(0x0D000000);   // Subtle 5% opacity black shadow

  // Progress Bar Track
  static const Color progressTrack = Color(0xFFE2E7EE); // Soft grey-blue track
}
