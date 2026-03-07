// TODO Phase 1.2: Add @Entity() ObjectBox annotation and run build_runner

enum PersonaGender { girlfriend, boyfriend }

enum PersonalityPreset { gentle, cheerful, mature, mysterious }

class PersonaConfig {
  int id = 0;
  late String name;
  late PersonaGender gender;
  late PersonalityPreset personalityPreset;
  List<String> hobbies = [];
  late String nicknameForUser;
  String avatarId = 'default';
  String voiceId = 'default';
  late DateTime createdAt;
}
