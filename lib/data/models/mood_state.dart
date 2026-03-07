// TODO Phase 1.2: Add @Entity() ObjectBox annotation and run build_runner

enum MoodType { happy, longing, playful, sad, excited }

class MoodState {
  int id = 0;
  late MoodType current;
  double intensity = 0.7; // 0.0 – 1.0
  late DateTime lastUpdatedAt;
  late DateTime lastInteractionAt;
}
