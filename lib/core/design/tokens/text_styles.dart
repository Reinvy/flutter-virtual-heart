// Design tokens — Tipografi Adaptif Tema (docs/DESIGN.md §2.2)
//
// Display/Headings beradaptasi dengan preset tema aktif:
//   - editorial → Newsreader
//   - romantic  → Cormorant Garamond
//   - classic   → Lora
//   - botanical → Outfit
// Body/UI: Inter (bersih, netral, nyaman dibaca panjang).
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/app_settings.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static TextStyle _displayFont(
    AppThemeStyle style, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return switch (style) {
      AppThemeStyle.editorial => GoogleFonts.newsreader(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      ),
      AppThemeStyle.romantic => GoogleFonts.cormorantGaramond(
        fontSize: fontSize + 2,
        fontWeight: FontWeight.w600,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      ),
      AppThemeStyle.classic => GoogleFonts.lora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      ),
      AppThemeStyle.botanical => GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      ),
    };
  }

  static AppThemeStyle _styleOf(BuildContext context) =>
      AppColors.paletteOf(context).style;

  // ── Display & Headings (style-explicit untuk AppTheme) ────────────────

  static TextStyle displayHeroForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 38,
        fontWeight: FontWeight.w600,
        height: 1.08,
        letterSpacing: -0.6,
        color: color,
      );

  static TextStyle displayLargeForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.12,
        letterSpacing: -0.4,
        color: color,
      );

  static TextStyle displayMediumForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 27,
        fontWeight: FontWeight.w600,
        height: 1.16,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle displaySmallForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.18,
        color: color,
      );

  static TextStyle appNameForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.15,
        color: color,
      );

  static TextStyle personaNameForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      );

  static TextStyle headingLargeForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: color,
      );

  static TextStyle headingMediumForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: color,
      );

  static TextStyle headingSmallForStyle(AppThemeStyle style, {Color? color}) =>
      _displayFont(
        style,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  // ── Display & Headings (context-aware) ────────────────────────────────

  /// Judul hero — 38sp SemiBold.
  static TextStyle displayHero(BuildContext context, {Color? color}) =>
      displayHeroForStyle(_styleOf(context), color: color);

  /// Judul layar besar — 32sp SemiBold.
  static TextStyle displayLarge(BuildContext context, {Color? color}) =>
      displayLargeForStyle(_styleOf(context), color: color);

  /// Judul kartu utama — 27sp SemiBold.
  static TextStyle displayMedium(BuildContext context, {Color? color}) =>
      displayMediumForStyle(_styleOf(context), color: color);

  /// Judul blok — 24sp SemiBold.
  static TextStyle displaySmall(BuildContext context, {Color? color}) =>
      displaySmallForStyle(_styleOf(context), color: color);

  /// Nama app — 30sp SemiBold.
  static TextStyle appName(BuildContext context, {Color? color}) =>
      appNameForStyle(_styleOf(context), color: color);

  /// Nama persona di AppBar — 20sp SemiBold.
  static TextStyle personaName(BuildContext context, {Color? color}) =>
      personaNameForStyle(_styleOf(context), color: color);

  /// Judul section — 22sp SemiBold.
  static TextStyle headingLarge(BuildContext context, {Color? color}) =>
      headingLargeForStyle(_styleOf(context), color: color);

  /// Sub-judul — 19sp SemiBold.
  static TextStyle headingMedium(BuildContext context, {Color? color}) =>
      headingMediumForStyle(_styleOf(context), color: color);

  /// Sub-judul kecil — 17sp SemiBold.
  static TextStyle headingSmall(BuildContext context, {Color? color}) =>
      headingSmallForStyle(_styleOf(context), color: color);

  // ── Inter (body / UI) ─────────────────────────────────────────────────

  /// Teks body besar — 15sp Regular.
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: color,
  );

  /// Teks body umum — 14sp Regular.
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color,
  );

  /// Teks bantu kecil — 12.5sp Regular.
  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color,
  );

  /// Teks chat — 15sp Regular.
  static TextStyle bubbleText({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: color,
  );

  /// Label settings — 15sp SemiBold.
  static TextStyle settingsLabel({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: color,
  );

  /// Judul UI besar — 18sp SemiBold.
  static TextStyle titleLarge({Color? color}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color,
  );

  /// Label UI kecil — 13sp SemiBold.
  static TextStyle titleSmall({Color? color}) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: color,
  );

  /// Hint input — 15sp Regular.
  static TextStyle inputHint({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color,
  );

  /// Label tombol — 15sp SemiBold.
  static TextStyle button({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
    color: color,
  );

  /// Mood indicator — 12.5sp Medium.
  static TextStyle moodIndicator({Color? color}) => GoogleFonts.inter(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: color,
  );

  /// Timestamp — 11sp Medium dengan angka tabular.
  static TextStyle timestamp({Color? color}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );

  /// Label section uppercase — 11sp Bold, letterSpacing 1.2.
  static TextStyle sectionLabel({Color? color}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.2,
    color: color,
  );

  /// Caption — 12sp Medium dengan angka tabular.
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );

  /// Badge — 10.5sp Bold dengan angka tabular.
  static TextStyle badge({Color? color}) => GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.3,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );
}
