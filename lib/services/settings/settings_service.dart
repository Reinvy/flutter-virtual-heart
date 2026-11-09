// Controller Settings (FR-18..FR-20) — kelola AppSettings & aksi data.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_logger.dart';
import '../../models/app_settings.dart';
import 'package:virtual_heart/services/database/objectbox_provider.dart';

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
    db.store.runInTransaction(TxMode.write, () => db.messageBox.removeAll());
    save(state.copyWith(conversationSummary: '', summaryMessageCount: 0));
  }

  /// Mereset data persona saja: persona, memori, mood, dan percakapan.
  ///
  /// Identitas model dan preferensi lain (tema, bahasa, suara, notifikasi)
  /// dipertahankan supaya pengguna tidak perlu mengunduh ulang model 1–2 GB.
  Future<void> resetPersonaData() async {
    final db = ref.read(objectBoxServiceProvider);
    db.store.runInTransaction(TxMode.write, () {
      db.personaBox.removeAll();
      db.memoryFactBox.removeAll();
      db.moodStateBox.removeAll();
      db.messageBox.removeAll();
    });
    save(
      state.copyWith(
        isPersonaSetup: false,
        conversationSummary: '',
        summaryMessageCount: 0,
      ),
    );
  }

  /// Mereset seluruh data lokal (FR-19): persona, memori, mood, pesan, settings,
  /// token HuggingFace, dan file ekspor chat.
  ///
  /// File model yang sudah diunduh **tidak** dihapus: identitas model
  /// (`modelVariant`/`modelSource`/`modelUrl`) ikut dipertahankan supaya model
  /// tetap bisa dipakai tanpa mengunduh ulang.
  Future<void> resetAllData() async {
    final db = ref.read(objectBoxServiceProvider);
    final previous = state;

    late AppSettings fresh;
    db.store.runInTransaction(TxMode.write, () {
      db.personaBox.removeAll();
      db.memoryFactBox.removeAll();
      db.moodStateBox.removeAll();
      db.messageBox.removeAll();
      db.appSettingsBox.removeAll();

      fresh = AppSettings(
        modelVariant: previous.modelVariant,
        modelSource: previous.modelSource,
        modelUrl: previous.modelUrl,
      );
      db.appSettingsBox.put(fresh);
    });

    await _clearHfToken();
    await _deleteExportFiles();

    if (ref.mounted) state = fresh;
  }

  /// Menghapus token HuggingFace dari penyimpanan preferensi.
  Future<void> _clearHfToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hf_token');
    } catch (e) {
      AppLogger.debug('HF token cleanup skipped', e);
    }
  }

  /// Menghapus file ekspor chat lama di dokumen aplikasi.
  Future<void> _deleteExportFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('virtualheart_') && name.endsWith('.txt')) {
          await entity.delete();
        }
      }
    } catch (e) {
      AppLogger.debug('Export file cleanup skipped', e);
    }
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
