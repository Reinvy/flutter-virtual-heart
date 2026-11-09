// Integration test — persistensi AppSettings di ObjectBox.
//
// Regresi yang dijaga: binding ObjectBox pernah stale sehingga 6 field
// (`ttsBackend`, `sttBackend`, `ttsModel`, `sttModel`, `modelSource`,
// `modelUrl`) tidak ikut tersimpan. Test ini menulis nilai non-default,
// menutup store, membuka ulang, lalu memastikan semua nilai kembali.
//
// Catatan: test butuh library native ObjectBox di host (`libobjectbox.so` di
// folder kerja atau path sistem). Bila tidak ada, test di-skip — lihat
// docs/TESTING.md.
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

  group('AppSettings persistence', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vh_objectbox_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test(
      'semua field model & suara bertahan setelah store dibuka ulang',
      () async {
        final path = tempDir.path;
        final previousDir = Directory.current.path;
        // Bindings ObjectBox mencari library di `./lib` relatif terhadap
        // direktori kerja proses.
        if (libDir != null) Directory.current = libDir;

        final first = await openStore(directory: path);
        first.box<AppSettings>().put(
          AppSettings(
            ttsBackend: 'system',
            sttBackend: 'system',
            ttsModel: 'qwen3',
            sttModel: 'moonshine',
            modelSource: 'file',
            modelUrl: 'https://example.com/model.litertlm',
            modelVariant: 'model-kustom.litertlm',
          ),
        );
        first.close();

        final reopened = await openStore(directory: path);
        final stored = reopened.box<AppSettings>().getAll().single;
        expect(stored.ttsBackend, 'system');
        expect(stored.sttBackend, 'system');
        expect(stored.ttsModel, 'qwen3');
        expect(stored.sttModel, 'moonshine');
        expect(stored.modelSource, 'file');
        expect(stored.modelUrl, 'https://example.com/model.litertlm');
        expect(stored.modelVariant, 'model-kustom.litertlm');
        reopened.close();
        Directory.current = previousDir;
      },
      skip: libDir == null ? 'Library native ObjectBox tidak tersedia di host' : false,
    );
  });
}
