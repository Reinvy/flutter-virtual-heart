// Design tokens — Spacing, Radius, Ukuran (docs/DESIGN.md §2.3–2.5)
//
// Nama baru mengikuti DESIGN.md. Alias lama (`xs`, `sm`, `md`, `radiusMd=12`…)
// dipertahankan agar kode yang belum dimigrasi tetap kompilasi.
abstract final class AppSizes {
  AppSizes._();

  // ── Spacing scale (DESIGN.md §2.3) ────────────────────────────────────
  static const double spaceXxs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // ── Radius (DESIGN.md §2.4) ───────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusFull = 999;

  // ── Ukuran ikon ────────────────────────────────────────────────────────
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;

  // ── Ukuran avatar ──────────────────────────────────────────────────────
  static const double avatarSm = 36;
  static const double avatarMd = 52;
  static const double avatarLg = 96;

  // ── Aksesibilitas ──────────────────────────────────────────────────────
  /// Target sentuh minimum (docs/DESIGN.md §5): 48 dp.
  static const double touchTarget = 48;

  // ── Chat bubble & input bar ────────────────────────────────────────────
  static const double bubbleMaxWidthFraction = 0.75;
  static const double inputBarHeight = 56;
  static const double bubblePaddingH = 14;
  static const double bubblePaddingV = 10;

  // ── Alias kompatibilitas (kode lama) ──────────────────────────────────
  static const double xs = spaceXxs;
  static const double sm = spaceXs;
  static const double md = spaceMd;
  static const double lg = spaceLg;
  static const double xl = spaceXl;
  static const double xxl = spaceXxl;
  static const double radiusXl = 28; // dipakai bottom sheet (dipertahankan)
}
