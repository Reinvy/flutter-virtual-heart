// Provider tema — menurunkan ThemeMode dari AppSettings (default light).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../features/settings/settings_controller.dart';

/// Menurunkan [ThemeMode] dari [AppSettings.theme] yang tersimpan.
///
/// Default = light (Romantic Light) sesuai docs/DESIGN.md §1.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(appSettingsProvider);
  switch (settings.theme) {
    case AppThemeSetting.dark:
      return ThemeMode.dark;
    case AppThemeSetting.light:
      return ThemeMode.light;
    case AppThemeSetting.system:
      return ThemeMode.system;
  }
});
