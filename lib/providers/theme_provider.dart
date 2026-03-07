import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import 'app_settings_provider.dart';

/// Derives the Flutter [ThemeMode] from the persisted [AppSettings.theme].
///
/// Whenever [appSettingsProvider] changes (e.g. the user toggles the theme in
/// settings), this provider updates and rebuilds any widget that watches it.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(appSettingsProvider);
  switch (settings.theme) {
    case AppTheme.dark:
      return ThemeMode.dark;
    case AppTheme.light:
      return ThemeMode.light;
    case AppTheme.system:
      return ThemeMode.system;
  }
});
