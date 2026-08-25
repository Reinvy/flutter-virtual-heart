// Controller Settings (FR-18..FR-20) — kelola AppSettings & aksi data.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_logger.dart';
import '../../core/l10n/app_strings.dart';
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

  /// Membaca ulang settings dari ObjectBox.
  void refresh() {
    state = ref.read(objectBoxServiceProvider).getOrCreateSettings();
  }

  /// Menghapus semua percakapan (FR-19).
  void deleteAllConversations() {
    ref.read(objectBoxServiceProvider).messageBox.removeAll();
  }

  /// Mereset seluruh data lokal (FR-19): persona, memori, mood, pesan, settings.
  void resetAllData() {
    final db = ref.read(objectBoxServiceProvider);
    db.personaBox.removeAll();
    db.memoryFactBox.removeAll();
    db.moodStateBox.removeAll();
    db.messageBox.removeAll();
    db.appSettingsBox.removeAll();
    state = db.getOrCreateSettings();
  }
}

/// Mengekspor riwayat chat ke file .txt di dokumen (FR-19 / peningkatan).
Future<String?> exportChatToFile() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'virtualheart_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString('VirtualHeart — Chat Export\n', flush: true);
    return fileName;
  } catch (e) {
    AppLogger.error('Export chat failed', e);
    return null;
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

/// Helper: ganti placeholder `{file}` pada string ekspor.
String formatExportSuccess(AppStrings strings, String fileName) =>
    strings.settingsExportSuccess.replaceAll('{file}', fileName);
