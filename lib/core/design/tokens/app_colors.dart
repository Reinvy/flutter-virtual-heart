// Design tokens — Warna Multi-Tema (docs/DESIGN.md §2.1)
//
// Sistem tema Atelier mendukung 4 preset (Editorial, Romantic, Classic, Botanical)
// masing-masing dengan mode Light dan Dark yang disetel independen (bukan inversi)
// serta kontras >= 4.5:1 (WCAG AA) pada seluruh pasangan teks/permukaan.
import 'package:material_ui/material_ui.dart';

import '../../../models/app_settings.dart';

/// Palet warna penuh untuk satu kombinasi [AppThemeStyle] × [Brightness].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.style,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.secondary,
    required this.secondarySoft,
    required this.accent,
    required this.accentDeep,
    required this.gold,
    required this.goldText,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnPrimary,
    required this.divider,
    required this.error,
    required this.success,
    required this.warning,
    required this.userBubbleBg,
    required this.bubbleUserOn,
    required this.userBubbleBorder,
  });

  final AppThemeStyle style;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color secondary;
  final Color secondarySoft;
  final Color accent;
  final Color accentDeep;
  final Color gold;
  final Color goldText;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnPrimary;
  final Color divider;
  final Color error;
  final Color success;
  final Color warning;
  final Color userBubbleBg;
  final Color bubbleUserOn;
  final Color userBubbleBorder;

  @override
  AppPalette copyWith({
    AppThemeStyle? style,
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? primary,
    Color? primaryDeep,
    Color? primarySoft,
    Color? secondary,
    Color? secondarySoft,
    Color? accent,
    Color? accentDeep,
    Color? gold,
    Color? goldText,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnPrimary,
    Color? divider,
    Color? error,
    Color? success,
    Color? warning,
    Color? userBubbleBg,
    Color? bubbleUserOn,
    Color? userBubbleBorder,
  }) {
    return AppPalette(
      style: style ?? this.style,
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      accent: accent ?? this.accent,
      accentDeep: accentDeep ?? this.accentDeep,
      gold: gold ?? this.gold,
      goldText: goldText ?? this.goldText,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      divider: divider ?? this.divider,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      userBubbleBg: userBubbleBg ?? this.userBubbleBg,
      bubbleUserOn: bubbleUserOn ?? this.bubbleUserOn,
      userBubbleBorder: userBubbleBorder ?? this.userBubbleBorder,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      style: t < 0.5 ? style : other.style,
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      userBubbleBg: Color.lerp(userBubbleBg, other.userBubbleBg, t)!,
      bubbleUserOn: Color.lerp(bubbleUserOn, other.bubbleUserOn, t)!,
      userBubbleBorder: Color.lerp(userBubbleBorder, other.userBubbleBorder, t)!,
    );
  }
}

/// Katalog 8 palet independen (4 preset × Light & Dark).
abstract final class AppPalettes {
  AppPalettes._();

  static const AppPalette editorialLight = AppPalette(
    style: AppThemeStyle.editorial,
    brightness: Brightness.light,
    background: Color(0xFFFAF8F4),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF3EFE7),
    surfaceMuted: Color(0xFFEAE4DA),
    primary: Color(0xFF18181D),
    primaryDeep: Color(0xFF18181D),
    primarySoft: Color(0xFFEFECE6),
    secondary: Color(0xFF7A5616),
    secondarySoft: Color(0xFFF5EFE2),
    accent: Color(0xFFC45A42),
    accentDeep: Color(0xFF9C3A25),
    gold: Color(0xFFB58934),
    goldText: Color(0xFF785614),
    textPrimary: Color(0xFF141418),
    textSecondary: Color(0xFF5A5652),
    textOnPrimary: Color(0xFFFAF8F4),
    divider: Color(0xFFE4DED4),
    error: Color(0xFFB3342E),
    success: Color(0xFF2D6B4A),
    warning: Color(0xFF8F6114),
    userBubbleBg: Color(0xFF1A191F),
    bubbleUserOn: Color(0xFFFAF8F4),
    userBubbleBorder: Color(0xFF1A191F),
  );

  static const AppPalette editorialDark = AppPalette(
    style: AppThemeStyle.editorial,
    brightness: Brightness.dark,
    background: Color(0xFF0C0D10),
    surface: Color(0xFF14151A),
    surfaceElevated: Color(0xFF1C1D24),
    surfaceMuted: Color(0xFF24262F),
    primary: Color(0xFFE2C17D),
    primaryDeep: Color(0xFFEDD49C),
    primarySoft: Color(0xFF2A2418),
    secondary: Color(0xFFD89C89),
    secondarySoft: Color(0xFF2B201D),
    accent: Color(0xFFE58872),
    accentDeep: Color(0xFFF0A492),
    gold: Color(0xFFE2C17D),
    goldText: Color(0xFFEDD49C),
    textPrimary: Color(0xFFF4F1EC),
    textSecondary: Color(0xFFABA69E),
    textOnPrimary: Color(0xFF12110E),
    divider: Color(0xFF272932),
    error: Color(0xFFF08A84),
    success: Color(0xFF7CC99E),
    warning: Color(0xFFE5BD6C),
    userBubbleBg: Color(0xFF24211B),
    bubbleUserOn: Color(0xFFF4F1EC),
    userBubbleBorder: Color(0xFF463C28),
  );

  static const AppPalette romanticLight = AppPalette(
    style: AppThemeStyle.romantic,
    brightness: Brightness.light,
    background: Color(0xFFFDF9F6),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF7EFEA),
    surfaceMuted: Color(0xFFEFE2DC),
    primary: Color(0xFF7A1F33),
    primaryDeep: Color(0xFF631728),
    primarySoft: Color(0xFFF4E3E6),
    secondary: Color(0xFF7E5614),
    secondarySoft: Color(0xFFF5EDE0),
    accent: Color(0xFFB8424D),
    accentDeep: Color(0xFF8F2C38),
    gold: Color(0xFFB38430),
    goldText: Color(0xFF755312),
    textPrimary: Color(0xFF1C1215),
    textSecondary: Color(0xFF5F4A50),
    textOnPrimary: Color(0xFFFDF9F6),
    divider: Color(0xFFE8DDD8),
    error: Color(0xFFB3342E),
    success: Color(0xFF2D6B4A),
    warning: Color(0xFF8F6114),
    userBubbleBg: Color(0xFF5E1727),
    bubbleUserOn: Color(0xFFFDF9F6),
    userBubbleBorder: Color(0xFF5E1727),
  );

  static const AppPalette romanticDark = AppPalette(
    style: AppThemeStyle.romantic,
    brightness: Brightness.dark,
    background: Color(0xFF110B0D),
    surface: Color(0xFF1A1114),
    surfaceElevated: Color(0xFF24181D),
    surfaceMuted: Color(0xFF2E1F25),
    primary: Color(0xFFE8A89A),
    primaryDeep: Color(0xFFF4C4BA),
    primarySoft: Color(0xFF3B2026),
    secondary: Color(0xFFE2C17D),
    secondarySoft: Color(0xFF2D2417),
    accent: Color(0xFFE57F89),
    accentDeep: Color(0xFFF2A5AD),
    gold: Color(0xFFE2C17D),
    goldText: Color(0xFFEDD49C),
    textPrimary: Color(0xFFF6EEF0),
    textSecondary: Color(0xFFB9A5AA),
    textOnPrimary: Color(0xFF1A0E11),
    divider: Color(0xFF342329),
    error: Color(0xFFF08A84),
    success: Color(0xFF7CC99E),
    warning: Color(0xFFE5BD6C),
    userBubbleBg: Color(0xFF361C24),
    bubbleUserOn: Color(0xFFF9EEF1),
    userBubbleBorder: Color(0xFF5A2E3B),
  );

  static const AppPalette classicLight = AppPalette(
    style: AppThemeStyle.classic,
    brightness: Brightness.light,
    background: Color(0xFFF6F4EE),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFEDE9DF),
    surfaceMuted: Color(0xFFE2DDD0),
    primary: Color(0xFF1C314E),
    primaryDeep: Color(0xFF15263D),
    primarySoft: Color(0xFFE3E8F0),
    secondary: Color(0xFF7A5B1A),
    secondarySoft: Color(0xFFF3EDE0),
    accent: Color(0xFF9E4A36),
    accentDeep: Color(0xFF853827),
    gold: Color(0xFFAA8232),
    goldText: Color(0xFF735415),
    textPrimary: Color(0xFF151920),
    textSecondary: Color(0xFF4D5560),
    textOnPrimary: Color(0xFFF8F7F3),
    divider: Color(0xFFDFDAD0),
    error: Color(0xFFB3342E),
    success: Color(0xFF2D6B4A),
    warning: Color(0xFF8F6114),
    userBubbleBg: Color(0xFF1C314E),
    bubbleUserOn: Color(0xFFF8F7F3),
    userBubbleBorder: Color(0xFF1C314E),
  );

  static const AppPalette classicDark = AppPalette(
    style: AppThemeStyle.classic,
    brightness: Brightness.dark,
    background: Color(0xFF0B1018),
    surface: Color(0xFF131B26),
    surfaceElevated: Color(0xFF1B2533),
    surfaceMuted: Color(0xFF233041),
    primary: Color(0xFFDFBE7A),
    primaryDeep: Color(0xFFECD39C),
    primarySoft: Color(0xFF262A24),
    secondary: Color(0xFF9CB7D9),
    secondarySoft: Color(0xFF1C293B),
    accent: Color(0xFFD98F7C),
    accentDeep: Color(0xFFEAA998),
    gold: Color(0xFFDFBE7A),
    goldText: Color(0xFFECD39C),
    textPrimary: Color(0xFFEEF2F6),
    textSecondary: Color(0xFFA5B0BE),
    textOnPrimary: Color(0xFF10151C),
    divider: Color(0xFF263344),
    error: Color(0xFFF08A84),
    success: Color(0xFF7CC99E),
    warning: Color(0xFFE5BD6C),
    userBubbleBg: Color(0xFF1B283A),
    bubbleUserOn: Color(0xFFEEF2F6),
    userBubbleBorder: Color(0xFF344A66),
  );

  static const AppPalette botanicalLight = AppPalette(
    style: AppThemeStyle.botanical,
    brightness: Brightness.light,
    background: Color(0xFFF5F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFECEEE7),
    surfaceMuted: Color(0xFFE1E5DC),
    primary: Color(0xFF1F4A38),
    primaryDeep: Color(0xFF173A2B),
    primarySoft: Color(0xFFE1ECE6),
    secondary: Color(0xFF854932),
    secondarySoft: Color(0xFFF4E9E4),
    accent: Color(0xFFB36144),
    accentDeep: Color(0xFF8C4128),
    gold: Color(0xFFA68032),
    goldText: Color(0xFF705416),
    textPrimary: Color(0xFF151B17),
    textSecondary: Color(0xFF4D5750),
    textOnPrimary: Color(0xFFF6F8F5),
    divider: Color(0xFFDCE0D7),
    error: Color(0xFFB3342E),
    success: Color(0xFF276342),
    warning: Color(0xFF8F6114),
    userBubbleBg: Color(0xFF1F4A38),
    bubbleUserOn: Color(0xFFF6F8F5),
    userBubbleBorder: Color(0xFF1F4A38),
  );

  static const AppPalette botanicalDark = AppPalette(
    style: AppThemeStyle.botanical,
    brightness: Brightness.dark,
    background: Color(0xFF0B110E),
    surface: Color(0xFF131C18),
    surfaceElevated: Color(0xFF1B2721),
    surfaceMuted: Color(0xFF23322B),
    primary: Color(0xFF9BD0B7),
    primaryDeep: Color(0xFFBDE3D0),
    primarySoft: Color(0xFF1A2E25),
    secondary: Color(0xFFE3A189),
    secondarySoft: Color(0xFF2D201B),
    accent: Color(0xFFE29B81),
    accentDeep: Color(0xFFEEB49E),
    gold: Color(0xFFD9BE78),
    goldText: Color(0xFFE8D298),
    textPrimary: Color(0xFFECF2EE),
    textSecondary: Color(0xFFA3B2A9),
    textOnPrimary: Color(0xFF0C1611),
    divider: Color(0xFF25342C),
    error: Color(0xFFF08A84),
    success: Color(0xFF7CC99E),
    warning: Color(0xFFE5BD6C),
    userBubbleBg: Color(0xFF1A2D24),
    bubbleUserOn: Color(0xFFECF2EE),
    userBubbleBorder: Color(0xFF2F4F40),
  );

  static AppPalette resolve(AppThemeStyle style, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (style) {
      AppThemeStyle.editorial => isDark ? editorialDark : editorialLight,
      AppThemeStyle.romantic => isDark ? romanticDark : romanticLight,
      AppThemeStyle.classic => isDark ? classicDark : classicLight,
      AppThemeStyle.botanical => isDark ? botanicalDark : botanicalLight,
    };
  }
}

abstract final class AppColors {
  AppColors._();

  // ── Default static tokens: Editorial Light ("Atelier Ivory") ──────────
  static const Color background = Color(0xFFFAF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF3EFE7);
  static const Color surfaceMuted = Color(0xFFEAE4DA);
  static const Color primary = Color(0xFF18181D);
  static const Color primaryDeep = Color(0xFF18181D);
  static const Color primarySoft = Color(0xFFEFECE6);
  static const Color secondary = Color(0xFF7A5616);
  static const Color secondarySoft = Color(0xFFF5EFE2);
  static const Color accent = Color(0xFFC45A42);
  static const Color accentDeep = Color(0xFF9C3A25);
  static const Color gold = Color(0xFFB58934);
  static const Color goldText = Color(0xFF785614);
  static const Color textPrimary = Color(0xFF141418);
  static const Color textSecondary = Color(0xFF5A5652);
  static const Color textOnPrimary = Color(0xFFFAF8F4);
  static const Color divider = Color(0xFFE4DED4);
  static const Color error = Color(0xFFB3342E);
  static const Color success = Color(0xFF2D6B4A);
  static const Color warning = Color(0xFF8F6114);
  static const Color userBubbleBg = Color(0xFF1A191F);
  static const Color bubbleUserOn = Color(0xFFFAF8F4);
  static const Color userBubbleBorder = Color(0xFF1A191F);

  // ── Helper theme- & brightness-aware ──────────────────────────────────
  static AppPalette paletteOf(BuildContext context) {
    final ext = Theme.of(context).extension<AppPalette>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark
        ? AppPalettes.editorialDark
        : AppPalettes.editorialLight;
  }

  static Color backgroundFor(BuildContext context) => paletteOf(context).background;

  static Color surfaceFor(BuildContext context) => paletteOf(context).surface;

  static Color surfaceElevatedFor(BuildContext context) =>
      paletteOf(context).surfaceElevated;

  static Color dividerFor(BuildContext context) => paletteOf(context).divider;

  static Color primaryDeepFor(BuildContext context) => paletteOf(context).primaryDeep;

  static Color accentFor(BuildContext context) => paletteOf(context).accent;

  static Color accentDeepFor(BuildContext context) => paletteOf(context).accentDeep;

  static Color secondaryFor(BuildContext context) => paletteOf(context).secondary;

  static Color goldFor(BuildContext context) => paletteOf(context).gold;

  static Color goldTextFor(BuildContext context) => paletteOf(context).goldText;

  static Color userBubbleBgFor(BuildContext context) => paletteOf(context).userBubbleBg;

  static Color bubbleUserOnFor(BuildContext context) => paletteOf(context).bubbleUserOn;

  static Color userBubbleBorderFor(BuildContext context) =>
      paletteOf(context).userBubbleBorder;

  static Color successFor(BuildContext context) => paletteOf(context).success;

  static Color warningFor(BuildContext context) => paletteOf(context).warning;

  static Color errorFor(BuildContext context) => paletteOf(context).error;
  static Color textSecondaryFor(BuildContext context) =>
      paletteOf(context).textSecondary;
}
