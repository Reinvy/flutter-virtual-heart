// Tema aplikasi (docs/DESIGN.md §2 & §5)
//
// **Default: Light mode (Sakura Light)** — latar blush sakura, permukaan
// bersih, aksen rose pink + ungu elektrik. Dark mode independen (bukan
// inversi) sebagai opsi pengguna.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_sizes.dart';

abstract final class AppTheme {
  AppTheme._();

  /// Tema default: Sakura Light.
  static ThemeData get light => _build(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.secondarySoft,
      onSecondaryContainer: AppColors.secondary,
      tertiary: AppColors.accent,
      onTertiary: AppColors.textOnPrimary,
      tertiaryContainer: Color(0xFFFBE0E5),
      onTertiaryContainer: Color(0xFF8E2A3C),
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: Color(0xFFFADCE0),
      onErrorContainer: Color(0xFF8E2431),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceDim: Color(0xFFF7E8EF),
      surfaceBright: AppColors.surface,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: Color(0xFFFBEFF5),
      surfaceContainer: Color(0xFFF9E9F0),
      surfaceContainerHigh: Color(0xFFF6E2EB),
      surfaceContainerHighest: Color(0xFFF1DBE5),
      onSurfaceVariant: AppColors.textSecondary,
      outline: Color(0xFFB89AA9),
      outlineVariant: AppColors.divider,
      shadow: Color(0x33241021),
      scrim: Color(0x66120D14),
      inverseSurface: Color(0xFF33202B),
      onInverseSurface: AppColors.textPrimaryDark,
      inversePrimary: Color(0xFFF8A9C6),
    ),
    scaffoldBg: AppColors.background,
    surface: AppColors.surface,
    surfaceAlt: AppColors.surfaceElevated,
    textColor: AppColors.textPrimary,
    subtleColor: AppColors.textSecondary,
    inputFill: AppColors.surfaceElevated,
    dividerColor: AppColors.divider,
    statusBarBrightness: Brightness.dark,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.textOnPrimaryDark,
      primaryContainer: AppColors.primarySoftDark,
      onPrimaryContainer: AppColors.primaryDeepDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.textOnPrimaryDark,
      secondaryContainer: AppColors.secondarySoftDark,
      onSecondaryContainer: AppColors.secondaryDark,
      tertiary: AppColors.accentDark,
      onTertiary: AppColors.textOnPrimaryDark,
      tertiaryContainer: Color(0xFF4A2430),
      onTertiaryContainer: Color(0xFFF8A9C6),
      error: AppColors.errorDark,
      onError: AppColors.textOnPrimaryDark,
      errorContainer: Color(0xFF54222B),
      onErrorContainer: Color(0xFFF3B0B8),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceDim: AppColors.surfaceDark,
      surfaceBright: Color(0xFF3A2436),
      surfaceContainerLowest: Color(0xFF160E19),
      surfaceContainerLow: Color(0xFF241724),
      surfaceContainer: Color(0xFF2A1B26),
      surfaceContainerHigh: Color(0xFF33212F),
      surfaceContainerHighest: Color(0xFF3E283A),
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: Color(0xFF8A7084),
      outlineVariant: AppColors.dividerDark,
      shadow: Color(0x99000000),
      scrim: Color(0xCC000000),
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: Color(0xFF33202B),
      inversePrimary: AppColors.primary,
    ),
    scaffoldBg: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    surfaceAlt: AppColors.surfaceElevatedDark,
    textColor: AppColors.textPrimaryDark,
    subtleColor: AppColors.textSecondaryDark,
    inputFill: AppColors.surfaceElevatedDark,
    dividerColor: AppColors.dividerDark,
    statusBarBrightness: Brightness.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color surface,
    required Color surfaceAlt,
    required Color textColor,
    required Color subtleColor,
    required Color inputFill,
    required Color dividerColor,
    required Brightness statusBarBrightness,
  }) {
    final baseTextTheme = GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.shipporiMincho(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displayMedium: GoogleFonts.shipporiMincho(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displaySmall: GoogleFonts.shipporiMincho(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.shipporiMincho(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.shipporiMincho(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.shipporiMincho(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.shipporiMincho(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: subtleColor),
      labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500, color: subtleColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: baseTextTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.shipporiMincho(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: textColor, size: AppSizes.iconMd),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarBrightness,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: subtleColor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceXs),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceLg, vertical: AppSizes.spaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceLg, vertical: AppSizes.spaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          side: BorderSide(color: colorScheme.secondary),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceLg, vertical: AppSizes.spaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
          selectedBackgroundColor: colorScheme.primaryContainer,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
          textStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
        labelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        secondaryLabelStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceSm, vertical: AppSizes.spaceXxs),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      iconTheme: IconThemeData(color: textColor, size: AppSizes.iconMd),

      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1, space: 0),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
        ),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.nunito(fontSize: 14, color: colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        titleTextStyle: GoogleFonts.shipporiMincho(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        contentTextStyle: GoogleFonts.nunito(fontSize: 14, color: subtleColor),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        hourMinuteTextStyle: GoogleFonts.nunito(fontSize: 40, fontWeight: FontWeight.w600, color: textColor),
        dialHandColor: colorScheme.primary,
        dialBackgroundColor: colorScheme.surfaceContainerHighest,
        entryModeIconColor: colorScheme.primary,
        dayPeriodTextStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
        dayPeriodColor: colorScheme.surfaceContainerHigh,
        helpTextStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: subtleColor),
      ),

      tooltipTheme: TooltipThemeData(
        textStyle: GoogleFonts.nunito(fontSize: 12, color: colorScheme.onInverseSurface),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),
    );
  }
}
