import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/memory_fact.dart';
import '../models/message.dart';
import '../models/mood_state.dart';
import '../models/persona_config.dart';
import '../../objectbox.g.dart';

class ObjectBoxService {
  static ObjectBoxService? _instance;

  late final Store store;

  late final Box<PersonaConfig> personaBox;
  late final Box<Message> messageBox;
  late final Box<MemoryFact> memoryFactBox;
  late final Box<MoodState> moodStateBox;
  late final Box<AppSettings> appSettingsBox;

  ObjectBoxService._();

  static Future<ObjectBoxService> create() async {
    if (_instance != null) return _instance!;

    final service = ObjectBoxService._();
    final appDir = await getApplicationDocumentsDirectory();
    service.store = await openStore(directory: '${appDir.path}/virtualheartdb');

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

  /// Returns existing AppSettings singleton or creates default one.
  AppSettings getOrCreateSettings() {
    final existing = appSettingsBox.getAll();
    if (existing.isNotEmpty) return existing.first;
    final defaults = AppSettings();
    appSettingsBox.put(defaults);
    return defaults;
  }

  void close() {
    store.close();
    _instance = null;
  }
}
