// Layar darurat bila bootstrap (engine AI / database) gagal sebelum runApp.
//
// Sengaja tidak memakai provider maupun lokalisasi (butuh database): layar ini
// harus selalu bisa dirender. Tema tetap dipakai supaya warna & tipografi
// konsisten.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'core/design/app_theme.dart';
import 'core/design/components/app_icon_badge.dart';
import 'core/design/components/app_scaffold.dart';
import 'core/design/components/primary_button.dart';
import 'core/design/tokens/app_sizes.dart';
import 'core/design/tokens/text_styles.dart';

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key});

  static const String _titleEn = 'VirtualHeart could not start';
  static const String _titleId = 'VirtualHeart tidak bisa dimulai';
  static const String _bodyEn =
      'The AI engine or local database could not be opened. Please restart the app.';
  static const String _bodyId =
      'Mesin AI atau database lokal tidak bisa dibuka. Silakan mulai ulang aplikasi.';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return AppScaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.spaceLg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.spaceLg),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIconBadge(
                          icon: Icons.error_outline_rounded,
                          color: scheme.error,
                        ),
                        const SizedBox(height: AppSizes.spaceMd),
                        Text(
                          _titleEn,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headingMedium(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceXxs),
                        Text(
                          _titleId,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleLarge(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceMd),
                        Text(
                          _bodyEn,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                            color: scheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceXs),
                        Text(
                          _bodyId,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(
                            color: scheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceLg),
                        PrimaryButton(
                          label: 'Close / Tutup',
                          onPressed: SystemNavigator.pop,
                        ),
                      ],
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
