import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import 'objectbox_provider.dart';

/// Manages [AppSettings] and persists changes to ObjectBox.
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final db = ref.read(objectBoxServiceProvider);
    return db.getOrCreateSettings();
  }

  /// Persists [updated] to ObjectBox and updates state.
  /// Using [updateShouldNotify] always-true ensures listeners rebuild even
  /// when the caller passes the same mutated object reference.
  void save(AppSettings updated) {
    ref.read(objectBoxServiceProvider).appSettingsBox.put(updated);
    state = updated;
  }

  @override
  bool updateShouldNotify(AppSettings previous, AppSettings next) => true;

  /// Re-reads settings from ObjectBox (e.g. after external write).
  void refresh() {
    state = ref.read(objectBoxServiceProvider).getOrCreateSettings();
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
