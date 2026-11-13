// Provider tema — menurunkan ThemeMode dan AppThemeStyle dari AppSettings.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

/// Menurunkan [ThemeMode] dari [AppSettings.theme] yang tersimpan.
///
/// Default = light sesuai docs/DESIGN.md §1.
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

/// Menurunkan preset gaya tema [AppThemeStyle] dari [AppSettings.themeStyle].
final themeStyleProvider = Provider<AppThemeStyle>(
  (ref) => ref.watch(appSettingsProvider.select((s) => s.themeStyle)),
);
