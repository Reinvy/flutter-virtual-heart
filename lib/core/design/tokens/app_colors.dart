// Design tokens — Warna (docs/DESIGN.md §2.1)
//
// Mode utama & default: **Romantic Light**. Semua nilai UI wajib memakai
// token ini — dilarang hardcode warna di widget.
//
// Aturan penamaan:
//   - Token umum (default light): `background`, `surface`, `primary`, dst.
//   - Varian mode eksplisit: `*Light` / `*Dark` untuk mode spesifik.
import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // ── Mode Utama (default): Romantic Light ───────────────────────────────
  static const Color background = Color(0xFFFDF6F9); // blush lembut
  static const Color surface = Color(0xFFFFFFFF); // bersih
  static const Color surfaceElevated = Color(0xFFFBEFF5); // rose sangat muda
  static const Color primary = Color(0xFFC2507A); // Rose Pink
  static const Color primarySoft = Color(0xFFF6DCE7); // rose muda (chip/badge)
  static const Color secondary = Color(0xFF7B5EA7); // Mauve
  static const Color secondarySoft = Color(0xFFEDE4F6); // lavender muda
  static const Color accent = Color(0xFFE8506A); // Heart Red
  static const Color textPrimary = Color(0xFF1A0A2E);
  static const Color textSecondary = Color(0xFF6E5A7D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFF0E2EA);
  static const Color success = Color(0xFF3E7C4F);
  static const Color warning = Color(0xFF9C6F1E);
  static const Color error = Color(0xFFB63C49);

  // ── Dark Mode ──────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0D0A0E);
  static const Color surfaceDark = Color(0xFF1A1320);
  static const Color surfaceElevatedDark = Color(0xFF241A2B);
  static const Color primaryDark = Color(0xFFC2507A);
  static const Color primarySoftDark = Color(0xFF3A2230);
  static const Color secondaryDark = Color(0xFF7B5EA7);
  static const Color secondarySoftDark = Color(0xFF332844);
  static const Color accentDark = Color(0xFFE8506A);
  static const Color textPrimaryDark = Color(0xFFF5EEF8);
  static const Color textSecondaryDark = Color(0xFFB9A8C4);
  static const Color textOnPrimaryDark = Color(0xFFFFFFFF);
  static const Color dividerDark = Color(0xFF2E2436);
  static const Color successDark = Color(0xFF7BC67E);
  static const Color warningDark = Color(0xFFE5B567);
  static const Color errorDark = Color(0xFFE5646F);

  // ── Alias kompatibilitas (kode lama yang belum dimigrasi) ─────────────
  /// @Deprecated — gunakan [AppColors.background] / varian Dark.
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color surfaceAlt = surfaceElevatedDark; // bottom sheet dark
  static const Color surfaceAltLight = surfaceElevated; // bottom sheet light
  static const Color primaryLight = Color(0xFFE8839F); // highlight/icon aktif
  static const Color userBubble = Color(0xFF8B3A6A); // (dark) — diganti solid primary
  static const Color aiBubble = Color(0xFF1E1528); // (dark)
  static const Color userBubbleLight = Color(0xFFF4CEDD);
  static const Color aiBubbleLight = Color(0xFFF0EAF5);
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color heartRed = accent;
}
