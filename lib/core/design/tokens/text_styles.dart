// Design tokens — Tipografi (docs/DESIGN.md §2.2)
//
// Heading: Playfair Display (serif romantis) | Body/UI: Nunito (sans bulat).
// Default warna mengikuti token (light = default).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  // ── Playfair Display (headings) ────────────────────────────────────────

  /// Nama app / judul besar — 22sp Bold.
  static TextStyle appName({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: color);

  /// Nama persona di AppBar — 18sp SemiBold.
  static TextStyle personaName({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: color);

  /// Judul section — 20sp Bold.
  static TextStyle headingLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: color);

  /// Sub-judul — 16sp SemiBold.
  static TextStyle headingSmall({Color color = AppColors.textPrimary}) =>
      GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  // ── Nunito (body / UI) ─────────────────────────────────────────────────

  /// Teks chat bubble — 15sp Regular.
  static TextStyle bubbleText({Color color = AppColors.textPrimary}) =>
      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: color);

  /// Label settings — 14sp Medium.
  static TextStyle settingsLabel({Color color = AppColors.textPrimary}) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500, color: color);

  /// Teks body umum — 14sp Regular.
  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  /// Mood indicator — 12sp Regular.
  static TextStyle moodIndicator({Color color = AppColors.textSecondary}) =>
      GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  /// Timestamp — 11sp Light.
  static TextStyle timestamp({Color color = AppColors.textSecondary}) =>
      GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w300, color: color);

  /// Hint input — 14sp Regular.
  static TextStyle inputHint({Color color = AppColors.textSecondary}) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  /// Label tombol — 14sp SemiBold.
  static TextStyle button({Color color = AppColors.textPrimary}) =>
      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: color);
}
