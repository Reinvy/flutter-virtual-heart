import 'package:flutter/material.dart';

// Dark mode color palette — PRD §7.2
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0D0A0E);
  static const Color surface = Color(0xFF1A1320);

  // Accents
  static const Color primary = Color(0xFFC2507A); // Rose Pink
  static const Color secondary = Color(0xFF7B5EA7); // Mauve Purple

  // Bubbles
  static const Color userBubble = Color(0xFF8B3A6A);
  static const Color aiBubble = Color(0xFF1E1528);

  // Text
  static const Color textPrimary = Color(0xFFF5EEF8);
  static const Color textSecondary = Color(0xFFB39DBD);

  // Emphasis
  static const Color heartRed = Color(0xFFE8506A);

  // Light mode (for future use)
  static const Color backgroundLight = Color(0xFFFDF6FF);
  static const Color surfaceLight = Color(0xFFF0E8F5);
  static const Color textPrimaryLight = Color(0xFF1A0A2E);
  static const Color textSecondaryLight = Color(0xFF6B5080);
}
