import 'package:objectbox/objectbox.dart';

enum MemoryCategory { personal, event, preference, date }

@Entity()
class MemoryFact {
  @Id()
  int id = 0;

  String key = '';
  String value = '';
  String? sourceSnippet;

  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime lastReferencedAt = DateTime.now();

  // Enum backing field (stored as int index)
  int categoryIndex = 0;

  MemoryCategory get category => MemoryCategory.values[categoryIndex];
  set category(MemoryCategory value) => categoryIndex = value.index;

  MemoryFact({
    this.id = 0,
    MemoryCategory category = MemoryCategory.personal,
    this.key = '',
    this.value = '',
    this.sourceSnippet,
    DateTime? createdAt,
    DateTime? lastReferencedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastReferencedAt = lastReferencedAt ?? DateTime.now() {
    categoryIndex = category.index;
  }
}
