// TODO Phase 1.2: Add @Entity() ObjectBox annotation and run build_runner

enum MemoryCategory { personal, event, preference, date }

class MemoryFact {
  int id = 0;
  late MemoryCategory category;
  late String key;
  late String value;
  String? sourceSnippet;
  late DateTime createdAt;
  late DateTime lastReferencedAt;
}
