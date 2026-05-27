import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  AppThemeColors get colors => Theme.of(this).extension<AppThemeColors>()!;
}
