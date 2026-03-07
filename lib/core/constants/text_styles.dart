// TODO Phase 1.1: Implement with google_fonts (Playfair Display + Nunito) — PRD §7.3

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(fontSize: 16, color: AppColors.textPrimary);

  static const TextStyle bodyMedium = TextStyle(fontSize: 14, color: AppColors.textPrimary);

  static const TextStyle bodySecondary = TextStyle(fontSize: 14, color: AppColors.textSecondary);

  static const TextStyle caption = TextStyle(fontSize: 12, color: AppColors.textSecondary);
}
