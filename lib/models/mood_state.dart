// Entity ObjectBox — State mood pasangan virtual (FR-09)
import 'package:objectbox/objectbox.dart';

enum MoodType { happy, longing, playful, sad, excited }

@Entity()
class MoodState {
  @Id()
  int id = 0;

  double intensity = 0.7; // 0.0 – 1.0

  @Property(type: PropertyType.date)
  DateTime lastUpdatedAt = DateTime.now();

  @Property(type: PropertyType.date)
  DateTime lastInteractionAt = DateTime.now();

  // Enum backing field (stored as int index)
  int currentIndex = 0;

  MoodType get current => MoodType.values[currentIndex];
  set current(MoodType value) => currentIndex = value.index;

  MoodState({
    this.id = 0,
    MoodType current = MoodType.happy,
    this.intensity = 0.7,
    DateTime? lastUpdatedAt,
    DateTime? lastInteractionAt,
  }) : lastUpdatedAt = lastUpdatedAt ?? DateTime.now(),
       lastInteractionAt = lastInteractionAt ?? DateTime.now() {
    currentIndex = current.index;
  }
}
