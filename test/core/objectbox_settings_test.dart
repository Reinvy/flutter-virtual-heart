// Integration test — persistensi AppSettings di ObjectBox.
//
// Regresi yang dijaga: binding ObjectBox pernah stale sehingga beberapa field
// tidak ikut tersimpan, dan baris settings lama bisa berisi nilai kosong.
// Test ini menulis nilai non-default untuk SETIAP field, menutup store,
// membuka ulang, lalu memastikan semua nilai kembali apa adanya.
//
// Catatan: test butuh library native ObjectBox di host (`libobjectbox.so` di
// folder kerja atau path sistem). Di CI library wajib ada (langkah install di
// workflow); di mesin lokal tanpa library test di-skip — lihat docs/TESTING.md.
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/objectbox.g.dart';

/// Direktori yang berisi `lib/libobjectbox.so` (atau `.dylib`).
///
/// Urutan: env `OBJECTBOX_LIB_DIR`, lalu folder kerja proyek (tempat
/// `install.sh` ObjectBox menaruh library), lalu path sistem.
String? _objectBoxLibDir() {
  if (!Platform.isLinux && !Platform.isMacOS) return null;
  final name = Platform.isLinux ? 'libobjectbox.so' : 'libobjectbox.dylib';
  final candidates = [
    ?Platform.environment['OBJECTBOX_LIB_DIR'],
    Directory.current.path,
  ];
  for (final dir in candidates) {
    try {
      DynamicLibrary.open('$dir/lib/$name');
      return dir;
    } catch (_) {
      // Coba kandidat berikutnya.
    }
  }
  try {
    DynamicLibrary.open(name);
    return Directory.current.path;
  } catch (_) {
    return null;
  }
}

void main() {
  final libDir = _objectBoxLibDir();
  final isCi = Platform.environment['CI'] == 'true';

  group('AppSettings persistence', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vh_objectbox_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('semua field bertahan setelah store dibuka ulang', () async {
      if (libDir == null && isCi) {
        fail('Library native ObjectBox wajib tersedia di CI');
      }

      final previousDir = Directory.current.path;
      // Bindings ObjectBox mencari library di `./lib` relatif terhadap
      // direktori kerja proses.
      Directory.current = libDir ?? previousDir;
      addTearDown(() => Directory.current = previousDir);

      const summary = 'Ringkasan percakapan lama yang harus ikut tersimpan.';

      final first = await openStore(directory: tempDir.path);
      first.box<AppSettings>().put(
        AppSettings(
          theme: AppThemeSetting.system,
          themeStyle: AppThemeStyle.romantic,
          language: AppLanguage.english,
          ttsEnabled: true,
          ttsAutoPlay: true,
          ttsBackend: 'system',
          sttBackend: 'system',
          ttsModel: 'qwen3',
          sttModel: 'moonshine',
          notificationMorningEnabled: true,
          notificationMorningTime: '06:45',
          notificationCheckinEnabled: true,
          notificationCheckinHours: 12,
          modelVariant: 'model-kustom.litertlm',
          modelSource: 'file',
          modelUrl: 'https://example.com/model.litertlm',
          isAgeVerified: true,
          isOnboardingDone: true,
          isPersonaSetup: true,
          conversationSummary: summary,
          summaryMessageCount: 30,
        ),
      );
      first.close();

      final reopened = await openStore(directory: tempDir.path);
      final stored = reopened.box<AppSettings>().getAll().single;

      expect(stored.theme, AppThemeSetting.system);
      expect(stored.themeIndex, 2);
      expect(stored.themeStyle, AppThemeStyle.romantic);
      expect(stored.themeStyleIndex, 1);
      expect(stored.language, AppLanguage.english);
      expect(stored.languageIndex, 1);
      expect(stored.ttsEnabled, isTrue);
      expect(stored.ttsAutoPlay, isTrue);
      expect(stored.ttsBackend, 'system');
      expect(stored.sttBackend, 'system');
      expect(stored.ttsModel, 'qwen3');
      expect(stored.sttModel, 'moonshine');
      expect(stored.notificationMorningEnabled, isTrue);
      expect(stored.notificationMorningTime, '06:45');
      expect(stored.notificationCheckinEnabled, isTrue);
      expect(stored.notificationCheckinHours, 12);
      expect(stored.modelVariant, 'model-kustom.litertlm');
      expect(stored.modelSource, 'file');
      expect(stored.modelUrl, 'https://example.com/model.litertlm');
      expect(stored.isAgeVerified, isTrue);
      expect(stored.isOnboardingDone, isTrue);
      expect(stored.isPersonaSetup, isTrue);
      expect(stored.conversationSummary, summary);
      expect(stored.summaryMessageCount, 30);
      reopened.close();
    }, skip: libDir == null && !isCi ? 'Library native ObjectBox tidak tersedia di host' : false);

    test('baris lama tanpa nilai baru dinormalkan', () {
      final legacy = AppSettings()
        ..ttsBackend = ''
        ..sttBackend = 'aneh'
        ..ttsModel = 'tidak-ada'
        ..notificationMorningTime = '99:99'
        ..notificationCheckinHours = 0
        ..modelSource = 'sideload'
        ..themeIndex = 99
        ..themeStyleIndex = 99
        ..languageIndex = -4;

      final fixed = legacy.normalized();

      expect(fixed.ttsBackend, 'system');
      expect(fixed.sttBackend, 'system');
      expect(fixed.ttsModel, 'inflect');
      expect(fixed.notificationMorningTime, '08:00');
      expect(fixed.notificationCheckinHours, 6);
      expect(fixed.modelSource, '');
      expect(fixed.themeIndex, AppThemeSetting.values.length - 1);
      expect(fixed.themeStyleIndex, AppThemeStyle.values.length - 1);
      expect(fixed.languageIndex, 0);
      // Getter tidak boleh melempar RangeError untuk index rusak.
      expect(legacy.theme, AppThemeSetting.values.last);
      expect(legacy.themeStyle, AppThemeStyle.values.last);
      expect(legacy.language, AppLanguage.indonesian);
    });

    test('modelVariant kosong dipertahankan (belum memilih model)', () {
      expect(AppSettings().normalized().modelVariant, '');
    });
  });
}
