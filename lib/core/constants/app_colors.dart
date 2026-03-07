import 'package:flutter/material.dart';

// Color palette — PRD §7.2
class AppColors {
  AppColors._();

  // ── Dark Mode ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0A0E);
  static const Color surface = Color(0xFF1A1320);
  static const Color surfaceAlt = Color(0xFF211829); // bottom sheet, settings

  static const Color primary = Color(0xFFC2507A); // Rose Pink
  static const Color primaryLight = Color(0xFFE8839F); // highlight, active icons
  static const Color secondary = Color(0xFF7B5EA7); // Mauve Purple

  static const Color userBubble = Color(0xFF8B3A6A);
  static const Color aiBubble = Color(0xFF1E1528);

  static const Color textPrimary = Color(0xFFF5EEF8);
  static const Color textSecondary = Color(0xFFB39DBD);

  static const Color heartRed = Color(0xFFE8506A);

  // ── Light Mode ────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFDF6F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFF5ECF4);

  static const Color userBubbleLight = Color(0xFFF4CEDD);
  static const Color aiBubbleLight = Color(0xFFF0EAF5);

  static const Color textPrimaryLight = Color(0xFF1A0A2E);
  static const Color textSecondaryLight = Color(0xFF6B5080);
}
