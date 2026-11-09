// Controller Settings (FR-18..FR-20) — kelola AppSettings & aksi data.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../models/objectbox_provider.dart';

/// Mengelola [AppSettings] dan mempersistensikannya ke ObjectBox.
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final db = ref.read(objectBoxServiceProvider);
    return db.getOrCreateSettings();
  }

  /// Menyimpan [updated] ke ObjectBox dan memperbarui state.
  void save(AppSettings updated) {
    ref.read(objectBoxServiceProvider).appSettingsBox.put(updated);
    state = updated;
  }

  @override
  bool updateShouldNotify(AppSettings previous, AppSettings next) => true;

  /// Menulis ulang ringkasan percakapan (FR-13).
  ///
  /// Satu-satunya jalur tulis `conversationSummary` — controller lain memanggil
  /// ini agar state Riverpod tetap sinkron dengan ObjectBox.
  void setConversationSummary(String summary) {
    save(state.copyWith(conversationSummary: summary));
  }

  /// Menghapus semua percakapan (FR-19): pesan + ringkasan konteksnya.
  void deleteAllConversations() {
    final db = ref.read(objectBoxServiceProvider);
    db.messageBox.removeAll();
    save(state.copyWith(conversationSummary: ''));
  }

  /// Mereset seluruh data lokal (FR-19): persona, memori, mood, pesan, settings.
  ///
  /// File model yang sudah diunduh **tidak** dihapus: identitas model
  /// (`modelVariant`/`modelSource`/`modelUrl`) ikut dipertahankan supaya model
  /// tetap bisa dipakai tanpa mengunduh ulang 1–2 GB.
  void resetAllData() {
    final db = ref.read(objectBoxServiceProvider);
    final previous = state;

    db.personaBox.removeAll();
    db.memoryFactBox.removeAll();
    db.moodStateBox.removeAll();
    db.messageBox.removeAll();
    db.appSettingsBox.removeAll();

    final fresh = db.getOrCreateSettings().copyWith(
      modelVariant: previous.modelVariant,
      modelSource: previous.modelSource,
      modelUrl: previous.modelUrl,
    );
    db.appSettingsBox.put(fresh);
    state = fresh;
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
