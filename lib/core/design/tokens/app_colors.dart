// Design tokens — Warna (docs/DESIGN.md §2.1)
//
// Tema: **Sakura Dusk / Senja Sakura** — kertas ivory hangat, tinta plum,
// satu aksen rose yang tenang, lavender sebagai aksen kedua.
// Mode utama & default: **Light**. Dark mode disetel independen (bukan inversi).
//
// Aturan penamaan:
//   - Token umum (default light): `background`, `surface`, `primary`, dst.
//   - Varian mode eksplisit: `*Dark` untuk mode spesifik.
//   - Teks kecil di light memakai `primaryDeep`/`accentDeep`/`goldText`
//     (kontras >= 4.5:1); `primary` dipakai untuk fill tombol & ikon besar.
//   - `accent`/`gold` murni dekoratif — jangan untuk teks kecil.
import 'package:material_ui/material_ui.dart';

abstract final class AppColors {
  AppColors._();

  // ── Mode Utama (default): Sakura Dusk Light ───────────────────────────
  static const Color background = Color(0xFFFFF8F4); // kertas ivory hangat
  static const Color surface = Color(0xFFFFFDFB);
  static const Color surfaceElevated = Color(0xFFFFF1EE);
  static const Color surfaceMuted = Color(0xFFF8E7ED);
  static const Color primary = Color(0xFFB23A63); // rose tenang
  static const Color primaryDeep = Color(0xFF8C2A4E); // rose gelap (teks kecil)
  static const Color primarySoft = Color(0xFFFBE0E9);
  static const Color secondary = Color(0xFF7357B8); // lavender plum
  static const Color secondarySoft = Color(0xFFEFE9FA);
  static const Color accent = Color(0xFFD95669); // dekoratif
  static const Color accentDeep = Color(0xFFA63C4E); // teks kecil di atas surface
  static const Color gold = Color(0xFFC79A3B); // dekoratif
  static const Color goldText = Color(0xFF8F6A1F); // teks kecil
  static const Color textPrimary = Color(0xFF2A1620); // tinta plum
  static const Color textSecondary = Color(0xFF6F5464);
  static const Color textOnPrimary = Color(0xFFFFF9FB);
  static const Color divider = Color(0xFFF0DDE5);
  static const Color error = Color(0xFFB93B4A);
  static const Color success = Color(0xFF3C7A55);
  static const Color warning = Color(0xFF966A20);

  // ── Gradien & permukaan khusus ────────────────────────────────────────
  static const Color actionStart = Color(0xFFB23A63);
  static const Color actionEnd = Color(0xFF9B2C53);
  static const Color bubbleUserStart = Color(0xFFB23A63);
  static const Color bubbleUserEnd = Color(0xFF8C2A4E);
  static const Color bubbleUserOn = Color(0xFFFFF9FB);
  static const Color bgTop = Color(0xFFFFF8F4);
  static const Color bgMid = Color(0xFFFFF3F7);
  static const Color bgBottom = Color(0xFFF7F1FC);
  static const Color profileTop = Color(0xFFF7DCE6);
  static const Color profileMid = Color(0xFFF3E8FA);
  static const Color profileEnd = Color(0xFFFFF8F4);

  // ── Dark Mode (disetel independen) ────────────────────────────────────
  static const Color backgroundDark = Color(0xFF140F16);
  static const Color surfaceDark = Color(0xFF1E1620);
  static const Color surfaceElevatedDark = Color(0xFF2A1F2B);
  static const Color surfaceMutedDark = Color(0xFF332434);
  static const Color primaryDark = Color(0xFFF7A0BD);
  static const Color primaryDeepDark = Color(0xFFFFC2D6);
  static const Color primarySoftDark = Color(0xFF4A2338);
  static const Color secondaryDark = Color(0xFFC9AEF5);
  static const Color secondarySoftDark = Color(0xFF362A4E);
  static const Color accentDark = Color(0xFFFF8A9C);
  static const Color accentDeepDark = Color(0xFFFFB0BE);
  static const Color goldDark = Color(0xFFEACB7A);
  static const Color goldTextDark = Color(0xFFF0D79A);
  static const Color textPrimaryDark = Color(0xFFFBF1F6);
  static const Color textSecondaryDark = Color(0xFFCDB6C7);
  static const Color textOnPrimaryDark = Color(0xFF2A0E1E);
  static const Color dividerDark = Color(0xFF3B2A3C);
  static const Color errorDark = Color(0xFFFF8D98);
  static const Color successDark = Color(0xFF8BD4A1);
  static const Color warningDark = Color(0xFFEAC37A);

  static const Color actionStartDark = Color(0xFFF7A0BD);
  static const Color actionEndDark = Color(0xFFD9739B);
  static const Color bubbleUserStartDark = Color(0xFF8A3459);
  static const Color bubbleUserEndDark = Color(0xFF5E213C);
  static const Color bubbleUserOnDark = Color(0xFFFFEAF2);
  static const Color bgTopDark = Color(0xFF100B12);
  static const Color bgMidDark = Color(0xFF170E19);
  static const Color bgBottomDark = Color(0xFF201326);
  static const Color profileTopDark = Color(0xFF3A1F31);
  static const Color profileMidDark = Color(0xFF24182E);
  static const Color profileEndDark = Color(0xFF1E1620);

  // ── Helper brightness-aware ───────────────────────────────────────────
  //
  // Token tanpa suffix hanya aman di light mode. Widget yang memakai warna
  // eksplisit (bukan ColorScheme) wajib lewat helper ini supaya kontras di
  // dark mode tidak rusak.

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryDeepFor(BuildContext context) =>
      _isDark(context) ? primaryDeepDark : primaryDeep;

  static Color accentFor(BuildContext context) =>
      _isDark(context) ? accentDark : accent;

  static Color accentDeepFor(BuildContext context) =>
      _isDark(context) ? accentDeepDark : accentDeep;

  static Color secondaryFor(BuildContext context) =>
      _isDark(context) ? secondaryDark : secondary;

  static Color goldFor(BuildContext context) =>
      _isDark(context) ? goldDark : gold;

  static Color goldTextFor(BuildContext context) =>
      _isDark(context) ? goldTextDark : goldText;

  static Color bubbleUserOnFor(BuildContext context) =>
      _isDark(context) ? bubbleUserOnDark : bubbleUserOn;

  static Color successFor(BuildContext context) =>
      _isDark(context) ? successDark : success;

  static Color errorFor(BuildContext context) =>
      _isDark(context) ? errorDark : error;

  static Color textSecondaryFor(BuildContext context) =>
      _isDark(context) ? textSecondaryDark : textSecondary;
}
