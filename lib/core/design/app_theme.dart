// Tema aplikasi (docs/DESIGN.md §2 & §5)
//
// **Default: Light mode (Sakura Dusk)** — kertas ivory hangat, tinta plum,
// aksen rose tenang + lavender. Dark mode independen (bukan inversi).
//
// Satu sumber tipografi: `AppTextStyles` membangun `TextTheme`; jangan
// mendefinisikan ukuran font kedua kali di sini.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_sizes.dart';
import 'tokens/text_styles.dart';

abstract final class AppTheme {
  AppTheme._();

  /// Tema default: Sakura Dusk Light.
  static final ThemeData light = _build(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: Color(0xFF7A2445),
      secondary: AppColors.secondary,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: AppColors.secondarySoft,
      onSecondaryContainer: Color(0xFF4A3585),
      tertiary: AppColors.accentDeep,
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFFBE0E4),
      onTertiaryContainer: Color(0xFF8B2F3C),
      error: AppColors.error,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFBE0E3),
      onErrorContainer: Color(0xFF7E2530),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceDim: Color(0xFFF6E9EE),
      surfaceBright: Color(0xFFFFFFFF),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFFFF7F5),
      surfaceContainer: Color(0xFFFAEDF1),
      surfaceContainerHigh: Color(0xFFF6E4EA),
      surfaceContainerHighest: Color(0xFFF1DAE3),
      onSurfaceVariant: AppColors.textSecondary,
      outline: Color(0xFFA98C9B),
      outlineVariant: AppColors.divider,
      shadow: Color(0x331A0F18),
      scrim: Color(0x66140F16),
      inverseSurface: Color(0xFF35202B),
      onInverseSurface: Color(0xFFFBEEF4),
      inversePrimary: Color(0xFFF7A0BD),
    ),
    textColor: AppColors.textPrimary,
    subtleColor: AppColors.textSecondary,
    statusBarBrightness: Brightness.dark,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.textOnPrimaryDark,
      primaryContainer: AppColors.primarySoftDark,
      onPrimaryContainer: Color(0xFFFFD6E4),
      secondary: AppColors.secondaryDark,
      onSecondary: Color(0xFF221338),
      secondaryContainer: AppColors.secondarySoftDark,
      onSecondaryContainer: Color(0xFFE7D9FF),
      tertiary: AppColors.accentDark,
      onTertiary: Color(0xFF3A0C18),
      tertiaryContainer: Color(0xFF4A2430),
      onTertiaryContainer: Color(0xFFFFD3DA),
      error: AppColors.errorDark,
      onError: Color(0xFF3B0A11),
      errorContainer: Color(0xFF54222B),
      onErrorContainer: Color(0xFFFFD9DD),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceDim: Color(0xFF1A121C),
      surfaceBright: Color(0xFF3A2A38),
      surfaceContainerLowest: Color(0xFF171019),
      surfaceContainerLow: Color(0xFF241A26),
      surfaceContainer: Color(0xFF2A1F2B),
      surfaceContainerHigh: Color(0xFF332434),
      surfaceContainerHighest: Color(0xFF3E2C3E),
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: Color(0xFF8D7387),
      outlineVariant: AppColors.dividerDark,
      shadow: Color(0x99000000),
      scrim: Color(0xCC000000),
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: Color(0xFF35202B),
      inversePrimary: AppColors.primary,
    ),
    textColor: AppColors.textPrimaryDark,
    subtleColor: AppColors.textSecondaryDark,
    statusBarBrightness: Brightness.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color textColor,
    required Color subtleColor,
    required Brightness statusBarBrightness,
  }) {
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayHero(color: textColor),
      displayMedium: AppTextStyles.displayLarge(color: textColor),
      displaySmall: AppTextStyles.displaySmall(color: textColor),
      headlineLarge: AppTextStyles.headingLarge(color: textColor),
      headlineMedium: AppTextStyles.headingMedium(color: textColor),
      headlineSmall: AppTextStyles.headingSmall(color: textColor),
      titleLarge: AppTextStyles.titleLarge(color: textColor),
      titleMedium: AppTextStyles.settingsLabel(color: textColor),
      titleSmall: AppTextStyles.titleSmall(color: textColor),
      bodyLarge: AppTextStyles.bodyLarge(color: textColor),
      bodyMedium: AppTextStyles.bodyMedium(color: textColor),
      bodySmall: AppTextStyles.bodySmall(color: subtleColor),
      labelLarge: AppTextStyles.button(color: textColor),
      labelMedium: AppTextStyles.caption(color: textColor),
      labelSmall: AppTextStyles.badge(color: subtleColor),
    );

    const pill = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.background,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: AppTextStyles.headingSmall(color: textColor),
        iconTheme: IconThemeData(color: textColor, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarBrightness,
        ),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        hintStyle: AppTextStyles.bodyMedium(color: subtleColor),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceMd,
          vertical: AppSizes.spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          minimumSize: const Size(0, AppSizes.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: pill,
          textStyle: AppTextStyles.button(color: colorScheme.onPrimary),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          side: BorderSide(color: colorScheme.secondary, width: 1.2),
          minimumSize: const Size(0, AppSizes.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: pill,
          textStyle: AppTextStyles.button(color: colorScheme.secondary),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AppTextStyles.button(color: colorScheme.primary),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          selectedForegroundColor: colorScheme.onPrimaryContainer,
          selectedBackgroundColor: colorScheme.primaryContainer,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSegment),
          ),
          textStyle: AppTextStyles.button(),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: pill,
        labelStyle: AppTextStyles.titleSmall(color: colorScheme.onSurface),
        secondaryLabelStyle: AppTextStyles.titleSmall(
          color: colorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceSm,
          vertical: AppSizes.spaceXxs,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceMd,
          vertical: AppSizes.spaceSm,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),

      iconTheme: IconThemeData(color: textColor, size: AppSizes.iconMd),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusSheet)),
        ),
        elevation: 0,
        showDragHandle: false,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTextStyles.bodyMedium(color: colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSizes.spaceMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        titleTextStyle: AppTextStyles.headingMedium(color: textColor),
        contentTextStyle: AppTextStyles.bodyMedium(color: subtleColor),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        hourMinuteTextStyle: AppTextStyles.displayLarge(color: textColor),
        dayPeriodTextStyle: AppTextStyles.bodyMedium(color: textColor),
        dialHandColor: colorScheme.primary,
        dialBackgroundColor: colorScheme.surfaceContainerHighest,
        entryModeIconColor: colorScheme.primary,
        dayPeriodColor: colorScheme.surfaceContainerHigh,
        helpTextStyle: AppTextStyles.caption(color: subtleColor),
      ),

      tooltipTheme: TooltipThemeData(
        textStyle: AppTextStyles.caption(color: colorScheme.onInverseSurface),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primaryContainer,
        selectionHandleColor: colorScheme.primary,
      ),

      extensions: [
        GptMarkdownThemeData(
          brightness: brightness,
          h1: AppTextStyles.headingLarge(color: textColor),
          h2: AppTextStyles.headingMedium(color: textColor),
          h3: AppTextStyles.headingSmall(color: textColor),
          h4: AppTextStyles.settingsLabel(color: textColor),
          linkColor: colorScheme.primary,
          highlightColor: colorScheme.primaryContainer,
          hrLineColor: colorScheme.outlineVariant,
          autoAddDividerLineAfterH1: false,
        ),
      ],
    );
  }
}
