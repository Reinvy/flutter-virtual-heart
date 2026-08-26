// Design tokens — Warna (docs/DESIGN.md §2.1)
//
// Tema: **Sakura Romance** — terinspirasi Yae Miko (Genshin Impact):
// pink sakura, putih hangat, aksen ungu elektrik (Electro), hati merah muda.
// Mode utama & default: **Light**. Dark mode disetel independen (bukan inversi).
//
// Aturan penamaan:
//   - Token umum (default light): `background`, `surface`, `primary`, dst.
//   - Varian mode eksplisit: `*Dark` untuk mode spesifik.
//   - Teks kecil di light memakai `primaryDeep` (kontras >= 4.5:1);
//     `primary` dipakai untuk fill tombol & ikon besar (>= 3:1).
import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // ── Mode Utama (default): Sakura Light ────────────────────────────────
  static const Color background = Color(0xFFFDF4F7); // blush sakura hangat
  static const Color surface = Color(0xFFFFFFFF); // bersih
  static const Color surfaceElevated = Color(0xFFFBE7EF); // rose sangat muda
  static const Color primary = Color(0xFFC24D7E); // Sakura Pink
  static const Color primaryDeep = Color(0xFF9E3A63); // sakura gelap (teks kecil)
  static const Color primarySoft = Color(0xFFF8DCE7); // rose muda (chip/badge)
  static const Color secondary = Color(0xFF6D4FA8); // Electro Purple
  static const Color secondarySoft = Color(0xFFEFE6FA); // lavender muda
  static const Color accent = Color(0xFFE8546E); // Heart Red
  static const Color gold = Color(0xFFC9A227); // sparkle / aksen dekoratif
  static const Color textPrimary = Color(0xFF241021);
  static const Color textSecondary = Color(0xFF6E5466);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFF2E1EA);
  static const Color success = Color(0xFF3E7C4F);
  static const Color warning = Color(0xFF9C6F1E);
  static const Color error = Color(0xFFC03948);

  // ── Dark Mode (disetel independen) ────────────────────────────────────
  static const Color backgroundDark = Color(0xFF120D14);
  static const Color surfaceDark = Color(0xFF1D1420);
  static const Color surfaceElevatedDark = Color(0xFF2A1B26);
  static const Color primaryDark = Color(0xFFF28CB0);
  static const Color primaryDeepDark = Color(0xFFF8A9C6);
  static const Color primarySoftDark = Color(0xFF47223A);
  static const Color secondaryDark = Color(0xFFB79BE0);
  static const Color secondarySoftDark = Color(0xFF352652);
  static const Color accentDark = Color(0xFFF4778C);
  static const Color goldDark = Color(0xFFE8C766);
  static const Color textPrimaryDark = Color(0xFFF7EFF5);
  static const Color textSecondaryDark = Color(0xFFC4AEC0);
  static const Color textOnPrimaryDark = Color(0xFF2A0E1E);
  static const Color dividerDark = Color(0xFF382639);
  static const Color successDark = Color(0xFF7BC67E);
  static const Color warningDark = Color(0xFFE5B567);
  static const Color errorDark = Color(0xFFEE6B77);

  // ── Alias kompatibilitas (kode lama, dipertahankan agar migrasi lancar) ─
  /// @Deprecated — gunakan [AppColors.background] / varian Dark.
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color surfaceAlt = surfaceElevatedDark; // bottom sheet dark
  static const Color surfaceAltLight = surfaceElevated; // bottom sheet light
  static const Color primaryLight = primaryDeep; // highlight/ikon aktif (kontras)
  static const Color userBubble = Color(0xFF8B3A6A); // (dark) — diganti solid primary
  static const Color aiBubble = Color(0xFF1E1528); // (dark)
  static const Color userBubbleLight = Color(0xFFF4CEDD);
  static const Color aiBubbleLight = Color(0xFFF0EAF5);
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color heartRed = accent;
}
