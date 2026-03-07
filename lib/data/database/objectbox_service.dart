// TODO Phase 1.2: Implement full ObjectBox service
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// to generate objectbox.g.dart after adding @Entity annotations to models.

class ObjectBoxService {
  static ObjectBoxService? _instance;

  ObjectBoxService._();

  static ObjectBoxService get instance {
    _instance ??= ObjectBoxService._();
    return _instance!;
  }

  // TODO Phase 1.2: Open ObjectBox store and expose collection boxes
  // late final Store store;
}
