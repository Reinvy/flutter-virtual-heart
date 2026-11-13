// Unit test — clamping getter enum pada seluruh entity ObjectBox.
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/models/memory_fact.dart';
import 'package:virtual_heart/models/message.dart';
import 'package:virtual_heart/models/mood_state.dart';
import 'package:virtual_heart/models/persona_config.dart';

void main() {
  group('Entity enum clamping', () {
    test('Message.role meng-clamp index negatif dan di luar batas', () {
      final low = Message()..roleIndex = -5;
      final high = Message()..roleIndex = 99;
      expect(low.role, MessageRole.user);
      expect(high.role, MessageRole.assistant);
    });

    test('PersonaConfig.gender dan personalityPreset meng-clamp index rusak', () {
      final low = PersonaConfig()
        ..genderIndex = -1
        ..personalityPresetIndex = -2;
      final high = PersonaConfig()
        ..genderIndex = 50
        ..personalityPresetIndex = 50;

      expect(low.gender, PersonaGender.girlfriend);
      expect(low.personalityPreset, PersonalityPreset.gentle);
      expect(high.gender, PersonaGender.boyfriend);
      expect(high.personalityPreset, PersonalityPreset.mysterious);
    });

    test('MoodState.current meng-clamp index rusak', () {
      final low = MoodState()..currentIndex = -3;
      final high = MoodState()..currentIndex = 42;
      expect(low.current, MoodType.happy);
      expect(high.current, MoodType.excited);
    });

    test('MemoryFact.category meng-clamp index rusak', () {
      final low = MemoryFact()..categoryIndex = -10;
      final high = MemoryFact()..categoryIndex = 99;
      expect(low.category, MemoryCategory.personal);
      expect(high.category, MemoryCategory.date);
    });

    test('AppSettings enum getters & hasSameValues', () {
      final corrupted = AppSettings()
        ..themeIndex = 99
        ..themeStyleIndex = -2
        ..languageIndex = 99;
      expect(corrupted.theme, AppThemeSetting.system);
      expect(corrupted.themeStyle, AppThemeStyle.editorial);
      expect(corrupted.language, AppLanguage.mixed);

      final a = AppSettings(theme: AppThemeSetting.dark, language: AppLanguage.english);
      final b = a.copyWith();
      expect(a.hasSameValues(b), isTrue);
      expect(a.hasSameValues(a.copyWith(ttsEnabled: true)), isFalse);
    });
  });
}
