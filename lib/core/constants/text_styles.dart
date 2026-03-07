// Typography — PRD §7.3
// Heading: Playfair Display  |  Body: Nunito

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Playfair Display (headings) ───────────────────────────────────────────

  /// App name / large heading — 22sp Bold
  static TextStyle appName({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: color);

  /// Persona name in AppBar — 18sp SemiBold
  static TextStyle personaName({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: color);

  /// Section heading — 20sp Bold
  static TextStyle headingLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: color);

  /// Sub-heading — 16sp SemiBold
  static TextStyle headingSmall({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  // ── Nunito (body / UI) ────────────────────────────────────────────────────

  /// Chat bubble text — 15sp Regular
  static TextStyle bubbleText({Color color = AppColors.textPrimary}) =>
      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: color);

  /// Settings label — 14sp Medium
  static TextStyle settingsLabel({Color color = AppColors.textPrimary}) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500, color: color);

  /// General body text — 14sp Regular
  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  /// Mood indicator subtitle — 12sp Regular
  static TextStyle moodIndicator({Color color = AppColors.textSecondary}) =>
      GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  /// Timestamp — 11sp Light
  static TextStyle timestamp({Color color = AppColors.textSecondary}) =>
      GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w300, color: color);

  /// Input hint / placeholder — 14sp Regular
  static TextStyle inputHint({Color color = AppColors.textSecondary}) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  /// Button text — 14sp SemiBold
  static TextStyle button({Color color = AppColors.textPrimary}) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: color);
}
