// Layar darurat bila bootstrap (engine AI / database) gagal sebelum runApp.
//
// Sengaja tidak memakai provider, lokalisasi (butuh database), atau GoogleFonts
// (butuh jaringan/asset): layar ini harus selalu bisa dirender dengan tema
// bawaan platform dan palet statis.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'core/design/tokens/app_colors.dart';
import 'core/design/tokens/app_sizes.dart';

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key});

  static const String _titleEn = 'VirtualHeart could not start';
  static const String _titleId = 'VirtualHeart tidak bisa dimulai';
  static const String _bodyEn =
      'The AI engine or local database could not be opened. Please restart the app.';
  static const String _bodyId =
      'Mesin AI atau database lokal tidak bisa dibuka. Silakan mulai ulang aplikasi.';

  static ThemeData _fallbackTheme(AppPalette palette) {
    final isDark = palette.brightness == Brightness.dark;
    final scheme = isDark
        ? ColorScheme.dark(
            primary: palette.primary,
            onPrimary: palette.textOnPrimary,
            surface: palette.surface,
            onSurface: palette.textPrimary,
            onSurfaceVariant: palette.textSecondary,
            error: palette.error,
            outlineVariant: palette.divider,
          )
        : ColorScheme.light(
            primary: palette.primary,
            onPrimary: palette.textOnPrimary,
            surface: palette.surface,
            onSurface: palette.textPrimary,
            onSurfaceVariant: palette.textSecondary,
            error: palette.error,
            outlineVariant: palette.divider,
          );
    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _fallbackTheme(AppPalettes.editorialLight),
      darkTheme: _fallbackTheme(AppPalettes.editorialDark),
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.spaceLg),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.spaceLg),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                        border: Border.all(color: scheme.error, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: scheme.error,
                          ),
                          const SizedBox(height: AppSizes.spaceMd),
                          Text(
                            _titleEn,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spaceXxs),
                          Text(
                            _titleId,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spaceMd),
                          Text(
                            _bodyEn,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spaceXs),
                          Text(
                            _bodyId,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spaceLg),
                          SizedBox(
                            width: double.infinity,
                            height: AppSizes.controlHeight,
                            child: FilledButton(
                              onPressed: SystemNavigator.pop,
                              child: const Text('Close / Tutup'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
