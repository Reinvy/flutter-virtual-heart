// Design tokens — Efek (docs/DESIGN.md §2.4)
//
// Gradien dan bayangan adalah bagian dari sistem, bukan dekorasi lokal:
// setiap layar memakai sumber yang sama agar depth dan warna konsisten.
// Semua fungsi memilih token `*Dark` saat brightness gelap.
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  AppGradients._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Tombol aksi utama dan elemen utama lain.
  static LinearGradient primaryAction(BuildContext context) => LinearGradient(
    colors: _isDark(context)
        ? const [AppColors.actionStartDark, AppColors.actionEndDark]
        : const [AppColors.actionStart, AppColors.actionEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Bubble pesan pengguna.
  static LinearGradient userBubble(BuildContext context) => LinearGradient(
    colors: _isDark(context)
        ? const [AppColors.bubbleUserStartDark, AppColors.bubbleUserEndDark]
        : const [AppColors.bubbleUserStart, AppColors.bubbleUserEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Latar aplikasi (kertas + cahaya senja).
  static LinearGradient background(BuildContext context) => LinearGradient(
    colors: _isDark(context)
        ? const [AppColors.bgTopDark, AppColors.bgMidDark, AppColors.bgBottomDark]
        : const [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0, 0.55, 1],
  );

  /// Hero profil persona.
  static LinearGradient profileHeader(BuildContext context) => LinearGradient(
    colors: _isDark(context)
        ? const [AppColors.profileTopDark, AppColors.profileMidDark, AppColors.profileEndDark]
        : const [AppColors.profileTop, AppColors.profileMid, AppColors.profileEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ring seleksi avatar / indikator aktif.
  static LinearGradient selectedRing(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LinearGradient(
      colors: [scheme.primary, scheme.secondary],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  /// Bloom radial untuk latar dekoratif.
  static RadialGradient bloom(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RadialGradient(
      colors: [scheme.primaryContainer, scheme.primary],
      center: const Alignment(-0.2, -0.3),
    );
  }
}

abstract final class AppShadows {
  AppShadows._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Kartu konten (section, tile terpilih).
  static List<BoxShadow> card(BuildContext context) => _isDark(context)
      ? const [
          BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 12)),
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ]
      : const [
          BoxShadow(color: Color(0x144A1D33), blurRadius: 24, offset: Offset(0, 10)),
          BoxShadow(color: Color(0x0A4A1D33), blurRadius: 4, offset: Offset(0, 2)),
        ];

  /// Elemen melayang (input bar, sheet header).
  static List<BoxShadow> floating(BuildContext context) => _isDark(context)
      ? const [
          BoxShadow(color: Color(0x77000000), blurRadius: 36, offset: Offset(0, 16)),
          BoxShadow(color: Color(0x3D000000), blurRadius: 8, offset: Offset(0, 4)),
        ]
      : const [
          BoxShadow(color: Color(0x1A4A1D33), blurRadius: 32, offset: Offset(0, 14)),
          BoxShadow(color: Color(0x0D4A1D33), blurRadius: 6, offset: Offset(0, 3)),
        ];

  /// Glow berwarna (tombol utama, avatar terpilih).
  static List<BoxShadow> glow(BuildContext context, Color color) => [
    BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 32),
  ];
}
