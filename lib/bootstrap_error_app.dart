// Layar darurat bila bootstrap (engine AI / database) gagal sebelum runApp.
//
// Sengaja tidak memakai provider, lokalisasi (butuh database), maupun tema
// aplikasi penuh: layar ini harus selalu bisa dirender.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'core/design/app_theme.dart';
import 'core/design/tokens/app_sizes.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
                  const SizedBox(height: AppSizes.spaceMd),
                  Text(
                    _titleEn,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.spaceXs),
                  Text(
                    _titleId,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.spaceMd),
                  Text(
                    _bodyEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSizes.spaceXs),
                  Text(
                    _bodyId,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSizes.spaceLg),
                  FilledButton(
                    onPressed: SystemNavigator.pop,
                    child: const Text('Close / Tutup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
