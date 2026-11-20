// Unit test — clamping getter enum pada seluruh entity ObjectBox.
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/models/ai_provider_profile.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/models/cloud_speech_config.dart';
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
        ..languageIndex = 99
        ..aiModeIndex = 99;
      expect(corrupted.theme, AppThemeSetting.system);
      expect(corrupted.themeStyle, AppThemeStyle.editorial);
      expect(corrupted.language, AppLanguage.mixed);
      expect(corrupted.aiMode, AiMode.cloud);

      final a = AppSettings(
        theme: AppThemeSetting.dark,
        language: AppLanguage.english,
        aiMode: AiMode.cloud,
        activeCloudProfileId: 7,
      );
      final b = a.copyWith();
      expect(a.hasSameValues(b), isTrue);
      expect(a.hasSameValues(a.copyWith(ttsEnabled: true)), isFalse);
      expect(a.hasSameValues(a.copyWith(aiMode: AiMode.local)), isFalse);
      expect(a.hasSameValues(a.copyWith(activeCloudProfileId: 8)), isFalse);
    });

    test('AiProviderProfile enum clamping, normalized(), headers & local network detection', () {
      final low = AiProviderProfile()..providerTypeIndex = -5;
      final high = AiProviderProfile()..providerTypeIndex = 99;
      expect(low.providerType, LlmProviderType.google);
      expect(high.providerType, LlmProviderType.openai);

      final dirty = AiProviderProfile(
        profileKey: '  p1  ',
        name: '  Claude  ',
        providerType: LlmProviderType.anthropic,
        temperature: 1.9,
        topP: 1.5,
        topK: 0,
        maxOutputTokens: 999999,
        presencePenalty: -9.0,
        frequencyPenalty: 9.0,
        reasoningEffort: 'invalid_effort',
        geminiSafetyLevel: 'invalid_safety',
        maxHistoryMessages: 500,
        maxMemoryFacts: 1,
        maxInputChars: 500,
        maxPromptChars: 999999,
        timeoutSeconds: 2,
        customHeadersJson: '{"X-Title": "VirtualHeart", "Empty": ""}',
      );
      final clean = dirty.normalized();
      expect(clean.profileKey, 'p1');
      expect(clean.name, 'Claude');
      expect(clean.temperature, 1.0); // Anthropic capped at 1.0
      expect(clean.topP, 1.0);
      expect(clean.topK, 1);
      expect(clean.maxOutputTokens, 32768);
      expect(clean.presencePenalty, -2.0);
      expect(clean.frequencyPenalty, 2.0);
      expect(clean.reasoningEffort, '');
      expect(clean.geminiSafetyLevel, 'default');
      expect(clean.maxHistoryMessages, 200);
      expect(clean.maxMemoryFacts, 5);
      expect(clean.maxInputChars, 2000);
      expect(clean.maxPromptChars, 256000);
      expect(clean.timeoutSeconds, 15);
      expect(clean.parsedCustomHeaders(), {'X-Title': 'VirtualHeart'});

      expect(AiProviderProfile.isLocalNetworkUrl('http://localhost:11434/v1'), isTrue);
      expect(AiProviderProfile.isLocalNetworkUrl('http://127.0.0.1:1234/v1'), isTrue);
      expect(AiProviderProfile.isLocalNetworkUrl('http://192.168.1.25:8000/v1'), isTrue);
      expect(AiProviderProfile.isLocalNetworkUrl('https://api.openai.com/v1'), isFalse);
      expect(AiProviderProfile.isLocalNetworkUrl(''), isFalse);
    });

    test('CloudSpeechConfig normalized() & hasSameValues()', () {
      final dirty = CloudSpeechConfig(
        elevenLabsVoiceId: '   ',
        elevenLabsStability: 4.0,
        elevenLabsSimilarityBoost: -1.0,
        elevenLabsStyle: 2.0,
        elevenLabsSpeed: 0.1,
        elevenLabsOutputFormat: 'ogg_bad',
        openaiTtsSpeed: 9.0,
        openaiTtsFormat: 'midi',
        openaiSttTemperature: 3.0,
        timeoutSeconds: 999,
      );
      final clean = dirty.normalized();
      expect(clean.elevenLabsVoiceId, 'EXAVITQu4vr4xnSDxMaL');
      expect(clean.elevenLabsStability, 1.0);
      expect(clean.elevenLabsSimilarityBoost, 0.0);
      expect(clean.elevenLabsStyle, 1.0);
      expect(clean.elevenLabsSpeed, 0.7);
      expect(clean.elevenLabsOutputFormat, 'mp3_44100_128');
      expect(clean.openaiTtsSpeed, 4.0);
      expect(clean.openaiTtsFormat, 'mp3');
      expect(clean.openaiSttTemperature, 1.0);
      expect(clean.timeoutSeconds, 120);

      expect(clean.hasSameValues(clean.copyWith()), isTrue);
      expect(clean.hasSameValues(clean.copyWith(elevenLabsStyle: 0.4)), isFalse);
    });
  });
}
