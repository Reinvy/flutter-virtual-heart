// Design tokens — Spacing, Radius, Ukuran (docs/DESIGN.md §2.3–2.5)
//
// Nama baru mengikuti DESIGN.md. Alias lama (`xs`, `sm`, `md`, `radiusMd=12`…)
// dipertahankan agar kode yang belum dimigrasi tetap kompilasi.
abstract final class AppSizes {
  AppSizes._();

  // ── Spacing scale ─────────────────────────────────────────────────────
  static const double spaceXxs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // ── Radius ────────────────────────────────────────────────────────────
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusBadge = 12;
  static const double radiusSegment = 14;
  static const double radiusMd = 16;
  static const double radiusControl = 18;
  static const double radiusPanel = 20;
  static const double radiusLg = 24;
  static const double radiusCard = 28;
  static const double radiusSheet = 32;
  static const double radiusBubble = 22;
  static const double radiusFull = 999;

  // ── Layout ────────────────────────────────────────────────────────────
  /// Lebar maksimum kolom konten di layar lebar.
  static const double contentMaxWidth = 720;

  /// Lebar maksimum bubble chat.
  static const double bubbleMaxWidth = 560;

  /// Padding horizontal standar halaman.
  static const double pageGutter = 24;

  /// Tinggi kontrol besar (tombol utama).
  static const double controlHeight = 52;

  /// Tinggi minimum baris settings.
  static const double rowMinHeight = 60;

  /// Tinggi maksimum input multi-baris di chat.
  static const double inputMaxHeight = 132;

  /// Tinggi dasar input bar chat.
  static const double chatInputHeight = 56;

  /// Ekor bubble (radius sudut dekat avatar).
  static const double bubbleTail = 6;

  // ── Ukuran ikon ───────────────────────────────────────────────────────
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;

  /// Wadah ikon berbingkai membulat.
  static const double iconBadge = 36;
  static const double iconBadgeSm = 28;

  // ── Ukuran avatar ─────────────────────────────────────────────────────
  static const double avatarXs = 28;
  static const double avatarSm = 36;
  static const double avatarNav = 44;
  static const double avatarMd = 52;
  static const double avatarCard = 64;
  static const double avatarRail = 76;
  static const double avatarProfile = 92;
  static const double avatarLg = 96;
  static const double avatarHero = 112;

  // ── Aksesibilitas ─────────────────────────────────────────────────────
  /// Target sentuh minimum (docs/DESIGN.md §5): 48 dp.
  static const double touchTarget = 48;
}
