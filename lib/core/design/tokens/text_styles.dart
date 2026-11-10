// Design tokens — Tipografi (docs/DESIGN.md §2.2)
//
// Display: Fraunces (serif lembut, optical-size besar — nuansa romantis).
// Body/UI: Plus Jakarta Sans (sans humanis — nyaman untuk percakapan).
//
// Semua helper menerima `Color?`: bila `null`, warna mengikuti
// `DefaultTextStyle`/theme sehingga otomatis benar di light & dark mode.
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  // ── Fraunces (display / headings) ─────────────────────────────────────

  /// Judul hero — 38sp SemiBold.
  static TextStyle displayHero({Color? color}) => GoogleFonts.fraunces(
    fontSize: 38,
    fontWeight: FontWeight.w600,
    height: 1.08,
    letterSpacing: -0.6,
    color: color,
  );

  /// Judul layar besar — 32sp SemiBold.
  static TextStyle displayLarge({Color? color}) => GoogleFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.4,
    color: color,
  );

  /// Judul kartu utama — 27sp SemiBold.
  static TextStyle displayMedium({Color? color}) => GoogleFonts.fraunces(
    fontSize: 27,
    fontWeight: FontWeight.w600,
    height: 1.16,
    letterSpacing: -0.2,
    color: color,
  );

  /// Judul blok — 24sp SemiBold.
  static TextStyle displaySmall({Color? color}) => GoogleFonts.fraunces(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.18,
    color: color,
  );

  /// Nama app — 30sp SemiBold.
  static TextStyle appName({Color? color}) => GoogleFonts.fraunces(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.15,
    color: color,
  );

  /// Nama persona di AppBar — 20sp SemiBold.
  static TextStyle personaName({Color? color}) => GoogleFonts.fraunces(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: color,
  );

  /// Judul section — 22sp SemiBold.
  static TextStyle headingLarge({Color? color}) => GoogleFonts.fraunces(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: color,
  );

  /// Sub-judul — 19sp SemiBold.
  static TextStyle headingMedium({Color? color}) => GoogleFonts.fraunces(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: color,
  );

  /// Sub-judul kecil — 17sp SemiBold.
  static TextStyle headingSmall({Color? color}) => GoogleFonts.fraunces(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color,
  );

  // ── Plus Jakarta Sans (body / UI) ─────────────────────────────────────

  /// Teks body besar — 15sp Regular.
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: color,
  );

  /// Teks body umum — 14sp Regular.
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color,
  );

  /// Teks bantu kecil — 12.5sp Regular.
  static TextStyle bodySmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: color,
  );

  /// Teks chat bubble — 15sp Regular.
  static TextStyle bubbleText({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: color,
  );

  /// Label settings — 15sp SemiBold.
  static TextStyle settingsLabel({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: color,
  );

  /// Judul UI besar — 18sp SemiBold.
  static TextStyle titleLarge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: color,
  );

  /// Label UI kecil — 13sp SemiBold.
  static TextStyle titleSmall({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: color,
  );

  /// Hint input — 15sp Regular.
  static TextStyle inputHint({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color,
  );

  /// Label tombol — 15sp SemiBold.
  static TextStyle button({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
    color: color,
  );

  /// Mood indicator — 12.5sp Medium.
  static TextStyle moodIndicator({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: color,
  );

  /// Timestamp — 11sp Medium.
  static TextStyle timestamp({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: color,
  );

  /// Label section uppercase — 11sp Bold, letterSpacing 1.4.
  static TextStyle sectionLabel({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.4,
    color: color,
  );

  /// Caption — 12sp Medium.
  static TextStyle caption({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: color,
  );

  /// Badge — 10.5sp Bold.
  static TextStyle badge({Color? color}) => GoogleFonts.plusJakartaSans(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.3,
    color: color,
  );
}
