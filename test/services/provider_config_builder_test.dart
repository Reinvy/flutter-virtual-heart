// Unit test — sanitasi & pemetaan parameter Genkit per provider.
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/models/ai_provider_profile.dart';
import 'package:virtual_heart/models/cloud_speech_config.dart';
import 'package:virtual_heart/services/ai/genkit/provider_config_builder.dart';

void main() {
  group('URL & language helpers', () {
    test('normalizeBaseUrl menghapus spasi & trailing slash', () {
      expect(normalizeBaseUrl('  '), isNull);
      expect(
        normalizeBaseUrl(' https://api.groq.com/openai/v1/// '),
        'https://api.groq.com/openai/v1',
      );
      expect(normalizeBaseUrl('http://localhost:11434/v1/'), 'http://localhost:11434/v1');
      expect(
        normalizeAnthropicBaseUrl('https://proxy.anthropic.example/v1/'),
        'https://proxy.anthropic.example',
      );
      expect(
        normalizeGoogleBaseUrl('https://gemini.proxy.example/v1beta/'),
        'https://gemini.proxy.example',
      );
    });

    test('isValidBaseUrl menerima kosong atau http/https dengan host', () {
      expect(isValidBaseUrl(''), isTrue);
      expect(isValidBaseUrl('https://openrouter.ai/api/v1'), isTrue);
      expect(isValidBaseUrl('http://127.0.0.1:11434/v1'), isTrue);
      expect(isValidBaseUrl('ftp://example.com'), isFalse);
      expect(isValidBaseUrl('not-a-url'), isFalse);
      expect(isValidBaseUrl('https://'), isFalse);
    });

    test('iso6391Language mengekstrak kode bahasa primer', () {
      expect(iso6391Language('id-ID'), 'id');
      expect(iso6391Language('en_US'), 'en');
      expect(iso6391Language('ja'), 'ja');
      expect(iso6391Language('  '), isNull);
      expect(iso6391Language(null), isNull);
    });
  });

  group('buildAnthropicOptions', () {
    test('tidak pernah mengirim temperature dan topP bersamaan', () {
      final profile = AiProviderProfile(
        providerType: LlmProviderType.anthropic,
        temperature: 1.5, // harus di-clamp ke 1.0
        topP: 0.9,
        topK: 40,
        maxOutputTokens: 4096,
      );

      final opts = buildAnthropicOptions(profile);
      expect(opts.temperature, 1.0);
      expect(opts.topP, isNull);
      expect(opts.topK, 40);
      expect(opts.maxTokens, 4096);
    });

    test('mengirim topP bila temperature null', () {
      final profile = AiProviderProfile(
        providerType: LlmProviderType.anthropic,
        temperature: null,
        topP: 0.85,
      );

      final opts = buildAnthropicOptions(profile);
      expect(opts.temperature, isNull);
      expect(opts.topP, 0.85);
    });

    test('extended thinking menonaktifkan sampling tak kompatibel dan menaikkan maxTokens', () {
      final profile = AiProviderProfile(
        providerType: LlmProviderType.anthropic,
        temperature: 0.8,
        topP: 0.9,
        topK: 50,
        maxOutputTokens: 2048,
        thinkingBudgetTokens: 4096,
      );

      final opts = buildAnthropicOptions(profile);
      expect(opts.thinking?.type, 'enabled');
      expect(opts.thinking?.budgetTokens, 4096);
      expect(opts.maxTokens, greaterThan(4096));
      expect(opts.temperature, isNull);
      expect(opts.topP, isNull);
      expect(opts.topK, isNull);
    });

    test('adaptive thinking dan outputConfig effort terpetakan', () {
      final profile = AiProviderProfile(
        providerType: LlmProviderType.anthropic,
        reasoningEffort: 'adaptive',
      );
      final opts = buildAnthropicOptions(profile);
      expect(opts.thinking?.type, 'adaptive');
      expect(opts.temperature, isNull);

      final effortProfile = AiProviderProfile(
        providerType: LlmProviderType.anthropic,
        reasoningEffort: 'high',
      );
      final effortOpts = buildAnthropicOptions(effortProfile);
      expect(effortOpts.outputConfig?.effort, 'high');
    });
  });

  group('buildGeminiOptions', () {
    test('memetakan parameter sampling, thinkingLevel, dan safetySettings', () {
      final profile = AiProviderProfile(
        providerType: LlmProviderType.google,
        temperature: 1.4,
        topP: 0.95,
        topK: 32,
        maxOutputTokens: 8192,
        presencePenalty: 0.3,
        frequencyPenalty: -0.2,
        stopSequences: const ['STOP'],
        seed: 7,
        reasoningEffort: 'medium',
        geminiSafetyLevel: 'block_only_high',
      );

      final opts = buildGeminiOptions(profile);
      expect(opts.temperature, 1.4);
      expect(opts.topP, 0.95);
      expect(opts.topK, 32);
      expect(opts.maxOutputTokens, 8192);
      expect(opts.presencePenalty, 0.3);
      expect(opts.frequencyPenalty, -0.2);
      expect(opts.stopSequences, const ['STOP']);
      expect(opts.seed, 7);
      expect(opts.thinkingConfig?.thinkingLevel, 'MEDIUM');
      expect(opts.thinkingConfig?.includeThoughts, isFalse);
      expect(opts.safetySettings?.length, 5);
      expect(opts.safetySettings?.first.threshold, 'BLOCK_ONLY_HIGH');
    });

    test('reasoningEffort none menyetel thinkingBudget 0 dan default safety mengembalikan null', () {
      final profile = AiProviderProfile(
        providerType: LlmProviderType.google,
        reasoningEffort: 'none',
        geminiSafetyLevel: 'default',
      );
      final opts = buildGeminiOptions(profile);
      expect(opts.thinkingConfig?.thinkingBudget, 0);
      expect(opts.safetySettings, isNull);
    });
  });

  group('buildOpenAIOptions & speech options', () {
    test('memetakan OpenAIChatOptions dan mengabaikan reasoningEffort tidak valid', () {
      final profile = AiProviderProfile(
        providerType: LlmProviderType.openai,
        temperature: 1.2,
        topP: 0.9,
        maxOutputTokens: 4096,
        presencePenalty: 0.5,
        frequencyPenalty: 0.2,
        reasoningEffort: 'adaptive', // khusus Anthropic, bukan enum OpenAI
      );

      final opts = buildOpenAIOptions(profile);
      expect(opts.temperature, 1.2);
      expect(opts.maxTokens, 4096);
      expect(opts.reasoningEffort, isNull);

      final withReasoning = buildOpenAIOptions(
        profile.copyWith(reasoningEffort: 'high'),
      );
      expect(withReasoning.reasoningEffort, 'high');
    });

    test('buildOpenAiSpeechOptions hanya menyertakan instructions pada model gpt-4o', () {
      final cfg = CloudSpeechConfig(
        openaiTtsModel: 'gpt-4o-mini-tts',
        openaiTtsVoice: 'nova',
        openaiTtsSpeed: 1.15,
        openaiTtsInstructions: 'Warm gentle whisper',
        openaiTtsFormat: 'mp3',
      );
      final opts = buildOpenAiSpeechOptions(cfg);
      expect(opts.voice, 'nova');
      expect(opts.speed, 1.15);
      expect(opts.instructions, 'Warm gentle whisper');
      expect(opts.responseFormat, 'mp3');

      final tts1Opts = buildOpenAiSpeechOptions(
        cfg.copyWith(openaiTtsModel: 'tts-1'),
      );
      expect(tts1Opts.instructions, isNull);
    });
  });
}
