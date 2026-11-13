// Tema aplikasi multi-preset (docs/DESIGN.md §2 & §5)
//
// Membangun ThemeData lengkap per kombinasi (AppThemeStyle, Brightness)
// dengan AppPalette sebagai ThemeExtension dan tipografi adaptif tema.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../models/app_settings.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_sizes.dart';
import 'tokens/text_styles.dart';

abstract final class AppTheme {
  AppTheme._();

  static final Map<AppThemeStyle, ThemeData> _lightCache = {};
  static final Map<AppThemeStyle, ThemeData> _darkCache = {};

  static final ThemeData light = lightFor(AppThemeStyle.editorial);
  static final ThemeData dark = darkFor(AppThemeStyle.editorial);

  static ThemeData lightFor(AppThemeStyle style) =>
      _lightCache.putIfAbsent(style, () => _buildLight(style));

  static ThemeData _buildLight(AppThemeStyle style) {
    final palette = AppPalettes.resolve(style, Brightness.light);
    return _build(
      palette: palette,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        onPrimary: palette.textOnPrimary,
        primaryContainer: palette.primarySoft,
        onPrimaryContainer: palette.primaryDeep,
        secondary: palette.secondary,
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: palette.secondarySoft,
        onSecondaryContainer: palette.secondary,
        tertiary: palette.accentDeep,
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: palette.secondarySoft,
        onTertiaryContainer: palette.accentDeep,
        error: palette.error,
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFFBEAE8),
        onErrorContainer: palette.error,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        surfaceDim: palette.surfaceMuted,
        surfaceBright: palette.surface,
        surfaceContainerLowest: palette.background,
        surfaceContainerLow: palette.surfaceElevated,
        surfaceContainer: palette.surfaceElevated,
        surfaceContainerHigh: palette.surfaceMuted,
        surfaceContainerHighest: palette.surfaceMuted,
        onSurfaceVariant: palette.textSecondary,
        outline: palette.textSecondary.withValues(alpha: 0.45),
        outlineVariant: palette.divider,
        shadow: const Color(0x14000000),
        scrim: const Color(0x66000000),
        inverseSurface: palette.textPrimary,
        onInverseSurface: palette.surface,
        inversePrimary: palette.primarySoft,
      ),
      statusBarBrightness: Brightness.dark,
    );
  }

  static ThemeData darkFor(AppThemeStyle style) =>
      _darkCache.putIfAbsent(style, () => _buildDark(style));

  static ThemeData _buildDark(AppThemeStyle style) {
    final palette = AppPalettes.resolve(style, Brightness.dark);
    return _build(
      palette: palette,
      colorScheme: ColorScheme.dark(
        primary: palette.primary,
        onPrimary: palette.textOnPrimary,
        primaryContainer: palette.primarySoft,
        onPrimaryContainer: palette.primaryDeep,
        secondary: palette.secondary,
        onSecondary: palette.textOnPrimary,
        secondaryContainer: palette.secondarySoft,
        onSecondaryContainer: palette.secondary,
        tertiary: palette.accentDeep,
        onTertiary: palette.textOnPrimary,
        tertiaryContainer: palette.secondarySoft,
        onTertiaryContainer: palette.accentDeep,
        error: palette.error,
        onError: const Color(0xFF280807),
        errorContainer: const Color(0xFF3D1918),
        onErrorContainer: palette.error,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        surfaceDim: palette.background,
        surfaceBright: palette.surfaceMuted,
        surfaceContainerLowest: palette.background,
        surfaceContainerLow: palette.surfaceElevated,
        surfaceContainer: palette.surfaceElevated,
        surfaceContainerHigh: palette.surfaceMuted,
        surfaceContainerHighest: palette.surfaceMuted,
        onSurfaceVariant: palette.textSecondary,
        outline: palette.textSecondary.withValues(alpha: 0.5),
        outlineVariant: palette.divider,
        shadow: const Color(0x66000000),
        scrim: const Color(0xAA000000),
        inverseSurface: palette.textPrimary,
        onInverseSurface: palette.background,
        inversePrimary: palette.primarySoft,
      ),
      statusBarBrightness: Brightness.light,
    );
  }

  static ThemeData _build({
    required AppPalette palette,
    required ColorScheme colorScheme,
    required Brightness statusBarBrightness,
  }) {
    final style = palette.style;
    final textColor = palette.textPrimary;
    final subtleColor = palette.textSecondary;

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayHeroForStyle(style, color: textColor),
      displayMedium: AppTextStyles.displayLargeForStyle(style, color: textColor),
      displaySmall: AppTextStyles.displaySmallForStyle(style, color: textColor),
      headlineLarge: AppTextStyles.headingLargeForStyle(style, color: textColor),
      headlineMedium: AppTextStyles.headingMediumForStyle(style, color: textColor),
      headlineSmall: AppTextStyles.headingSmallForStyle(style, color: textColor),
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

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusControl),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: AppTextStyles.headingSmallForStyle(
          style,
          color: textColor,
        ),
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
          side: BorderSide(color: colorScheme.outlineVariant),
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
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
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
          shape: controlShape,
          textStyle: AppTextStyles.button(color: colorScheme.onPrimary),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.2),
          minimumSize: const Size(0, AppSizes.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: controlShape,
          textStyle: AppTextStyles.button(color: colorScheme.onSurface),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primaryDeep,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: AppTextStyles.button(color: palette.primaryDeep),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusSheet),
          ),
        ),
        elevation: 0,
        showDragHandle: false,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTextStyles.bodyMedium(
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSizes.spaceMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        titleTextStyle: AppTextStyles.headingMediumForStyle(
          style,
          color: textColor,
        ),
        contentTextStyle: AppTextStyles.bodyMedium(color: subtleColor),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        hourMinuteTextStyle: AppTextStyles.displayLargeForStyle(
          style,
          color: textColor,
        ),
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
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primaryContainer,
        selectionHandleColor: colorScheme.primary,
      ),

      extensions: [
        palette,
        GptMarkdownThemeData(
          brightness: palette.brightness,
          h1: AppTextStyles.headingLargeForStyle(style, color: textColor),
          h2: AppTextStyles.headingMediumForStyle(style, color: textColor),
          h3: AppTextStyles.headingSmallForStyle(style, color: textColor),
          h4: AppTextStyles.settingsLabel(color: textColor),
          linkColor: palette.primaryDeep,
          highlightColor: colorScheme.primaryContainer,
          hrLineColor: colorScheme.outlineVariant,
          autoAddDividerLineAfterH1: false,
        ),
      ],
    );
  }
}
