// Service database — ObjectBox (init & box access)
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_logger.dart';

import '../../models/app_settings.dart';
import '../../models/memory_fact.dart';
import '../../models/message.dart';
import '../../models/mood_state.dart';
import '../../models/persona_config.dart';
import '../../objectbox.g.dart';
import '../mood_store.dart';

class ObjectBoxService implements MoodStore {
  static ObjectBoxService? _instance;

  late final Store store;

  late final Box<PersonaConfig> personaBox;
  late final Box<Message> messageBox;
  late final Box<MemoryFact> memoryFactBox;

  @override
  late final Box<MoodState> moodStateBox;

  late final Box<AppSettings> appSettingsBox;

  ObjectBoxService._();

  static Future<ObjectBoxService> create() async {
    if (_instance != null) return _instance!;

    final service = ObjectBoxService._();
    final appDir = await getApplicationDocumentsDirectory();
    final directory = '${appDir.path}/virtualheartdb';
    try {
      service.store = await openStore(directory: directory);
    } catch (e) {
      // Store tidak bisa dibuka (korup/versi tidak kompatibel): pindahkan
      // direktori lama agar aplikasi tetap bisa jalan dengan data kosong.
      AppLogger.warn('ObjectBox open failed, attempting recovery', e);
      final dir = Directory(directory);
      if (!await dir.exists()) rethrow;
      final backup = '$directory.corrupt-${DateTime.now().millisecondsSinceEpoch}';
      try {
        await dir.rename(backup);
        AppLogger.warn('Corrupt store moved to $backup', null);
      } catch (renameError) {
        AppLogger.error('Corrupt store backup failed', renameError);
        rethrow;
      }
      service.store = await openStore(directory: directory);
    }

    service.personaBox = service.store.box<PersonaConfig>();
    service.messageBox = service.store.box<Message>();
    service.memoryFactBox = service.store.box<MemoryFact>();
    service.moodStateBox = service.store.box<MoodState>();
    service.appSettingsBox = service.store.box<AppSettings>();

    _instance = service;
    return service;
  }

  static ObjectBoxService get instance {
    assert(_instance != null, 'ObjectBoxService.create() must be called first.');
    return _instance!;
  }

  /// Mengembalikan [AppSettings] kanonik (baris id terkecil) atau membuat
  /// default baru, lalu menormalkan nilai yang mungkin rusak.
  ///
  /// Baris duplikat (bug lama) dihapus agar tidak ada dua sumber kebenaran.
  AppSettings getOrCreateSettings() {
    final all = appSettingsBox.getAll()..sort((a, b) => a.id.compareTo(b.id));
    if (all.isEmpty) {
      final defaults = AppSettings().normalized();
      appSettingsBox.put(defaults);
      return defaults;
    }
    if (all.length > 1) {
      appSettingsBox.removeMany(all.skip(1).map((row) => row.id).toList());
    }
    final canonical = all.first.normalized();
    appSettingsBox.put(canonical);
    return canonical;
  }

  void close() {
    store.close();
    _instance = null;
  }
}
