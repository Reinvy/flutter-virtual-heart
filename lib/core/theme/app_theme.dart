// TODO Phase 1.1: Implement full ThemeData with google_fonts tokens

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      onPrimary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
    ),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surfaceLight,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      onPrimary: AppColors.textPrimary,
      onSurface: AppColors.textPrimaryLight,
    ),
  );
}
