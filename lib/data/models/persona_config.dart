import 'package:objectbox/objectbox.dart';

enum PersonaGender { girlfriend, boyfriend }

enum PersonalityPreset { gentle, cheerful, mature, mysterious }

@Entity()
class PersonaConfig {
  @Id()
  int id = 0;

  String name = '';
  String nicknameForUser = '';
  String avatarId = 'default';
  String voiceId = 'default';

  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  // Enum backing fields (stored as int index)
  int genderIndex = 0;
  int personalityPresetIndex = 0;

  List<String> hobbies = [];

  PersonaGender get gender => PersonaGender.values[genderIndex];
  set gender(PersonaGender value) => genderIndex = value.index;

  PersonalityPreset get personalityPreset => PersonalityPreset.values[personalityPresetIndex];
  set personalityPreset(PersonalityPreset value) => personalityPresetIndex = value.index;

  PersonaConfig({
    this.id = 0,
    PersonaGender gender = PersonaGender.girlfriend,
    PersonalityPreset personalityPreset = PersonalityPreset.gentle,
    this.name = '',
    List<String>? hobbies,
    this.nicknameForUser = '',
    this.avatarId = 'default',
    this.voiceId = 'default',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    genderIndex = gender.index;
    personalityPresetIndex = personalityPreset.index;
    this.hobbies = hobbies ?? [];
  }
}
