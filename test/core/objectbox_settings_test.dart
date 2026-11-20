// Integration test — persistensi AppSettings di ObjectBox.
//
// Regresi yang dijaga: binding ObjectBox pernah stale sehingga beberapa field
// tidak ikut tersimpan, dan baris settings lama bisa berisi nilai kosong.
// Test ini menulis nilai non-default untuk SETIAP field, menutup store,
// membuka ulang, lalu memastikan semua nilai kembali apa adanya.
//
// Catatan: test butuh library native ObjectBox di host (`libobjectbox.so` di
// folder kerja atau path sistem). Di CI library wajib ada (langkah install di
// workflow); di mesin lokal tanpa library test di-skip — lihat docs/TESTING.md.
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/models/ai_provider_profile.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/models/cloud_speech_config.dart';
import 'package:virtual_heart/objectbox.g.dart';

/// Direktori yang berisi `lib/libobjectbox.so` (atau `.dylib`).
///
/// Urutan: env `OBJECTBOX_LIB_DIR`, lalu folder kerja proyek (tempat
/// `install.sh` ObjectBox menaruh library), lalu path sistem.
String? _objectBoxLibDir() {
  if (!Platform.isLinux && !Platform.isMacOS) return null;
  final name = Platform.isLinux ? 'libobjectbox.so' : 'libobjectbox.dylib';
  final candidates = [
    ?Platform.environment['OBJECTBOX_LIB_DIR'],
    Directory.current.path,
  ];
  for (final dir in candidates) {
    try {
      DynamicLibrary.open('$dir/lib/$name');
      return dir;
    } catch (_) {
      // Coba kandidat berikutnya.
    }
  }
  try {
    DynamicLibrary.open(name);
    return Directory.current.path;
  } catch (_) {
    return null;
  }
}

void main() {
  final libDir = _objectBoxLibDir();
  final isCi = Platform.environment['CI'] == 'true';

  group('AppSettings persistence', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vh_objectbox_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('semua field bertahan setelah store dibuka ulang', () async {
      if (libDir == null && isCi) {
        fail('Library native ObjectBox wajib tersedia di CI');
      }

      final previousDir = Directory.current.path;
      // Bindings ObjectBox mencari library di `./lib` relatif terhadap
      // direktori kerja proses.
      Directory.current = libDir ?? previousDir;
      addTearDown(() => Directory.current = previousDir);

      const summary = 'Ringkasan percakapan lama yang harus ikut tersimpan.';

      final first = await openStore(directory: tempDir.path);
      first.box<AppSettings>().put(
        AppSettings(
          theme: AppThemeSetting.system,
          themeStyle: AppThemeStyle.romantic,
          language: AppLanguage.english,
          aiMode: AiMode.cloud,
          ttsEnabled: true,
          ttsAutoPlay: true,
          ttsBackend: 'elevenlabs',
          sttBackend: 'openai',
          ttsModel: 'qwen3',
          sttModel: 'moonshine',
          notificationMorningEnabled: true,
          notificationMorningTime: '06:45',
          notificationCheckinEnabled: true,
          notificationCheckinHours: 12,
          modelVariant: 'model-kustom.litertlm',
          modelSource: 'file',
          modelUrl: 'https://example.com/model.litertlm',
          activeCloudProfileId: 42,
          isAgeVerified: true,
          isOnboardingDone: true,
          isPersonaSetup: true,
          conversationSummary: summary,
          summaryMessageCount: 30,
        ),
      );
      first.box<AiProviderProfile>().put(
        AiProviderProfile(
          profileKey: 'openrouter_1',
          name: 'OpenRouter Test',
          providerType: LlmProviderType.openai,
          presetId: 'openrouter',
          baseUrl: 'https://openrouter.ai/api/v1',
          modelId: 'anthropic/claude-sonnet-4.6',
          customHeadersJson: '{"X-Title":"VH"}',
          stripStreamOptions: true,
          temperature: 1.15,
          topP: 0.92,
          topK: 40,
          maxOutputTokens: 4096,
          presencePenalty: 0.4,
          frequencyPenalty: -0.2,
          stopSequences: const ['END', '###'],
          seed: 12345,
          reasoningEffort: 'medium',
          thinkingBudgetTokens: 2048,
          geminiSafetyLevel: 'block_only_high',
          maxHistoryMessages: 120,
          maxMemoryFacts: 80,
          maxInputChars: 32000,
          maxPromptChars: 128000,
          enforceShortReply: true,
          customSystemPrompt: 'Always speak poetically.',
          timeoutSeconds: 90,
          enableBackgroundTasks: false,
          backgroundModelId: 'google/gemini-2.5-flash-lite',
        ),
      );
      first.box<CloudSpeechConfig>().put(
        CloudSpeechConfig(
          elevenLabsBaseUrl: 'https://proxy.elevenlabs.local/v1',
          elevenLabsVoiceId: 'voice_123',
          elevenLabsVoiceName: 'Custom Voice',
          elevenLabsTtsModel: 'eleven_flash_v2_5',
          elevenLabsStability: 0.35,
          elevenLabsSimilarityBoost: 0.85,
          elevenLabsStyle: 0.25,
          elevenLabsSpeed: 1.1,
          elevenLabsUseSpeakerBoost: false,
          elevenLabsOutputFormat: 'mp3_44100_64',
          elevenLabsSttModel: 'scribe_v1',
          elevenLabsSttTagAudioEvents: true,
          elevenLabsSttDiarize: true,
          openaiTtsReuseLlmKey: false,
          openaiTtsBaseUrl: 'https://tts.example.com/v1',
          openaiTtsModel: 'tts-1-hd',
          openaiTtsVoice: 'nova',
          openaiTtsSpeed: 1.25,
          openaiTtsInstructions: 'Speak softly',
          openaiTtsFormat: 'wav',
          openaiSttReuseLlmKey: false,
          openaiSttBaseUrl: 'https://api.groq.com/openai/v1',
          openaiSttModel: 'whisper-large-v3-turbo',
          openaiSttPrompt: 'VirtualHeart',
          openaiSttTemperature: 0.2,
          googleSpeechReuseLlmKey: false,
          googleSpeechBaseUrl: 'https://gemini-proxy.example.com',
          googleTtsModel: 'gemini-2.5-pro-preview-tts',
          googleTtsVoiceName: 'Zephyr',
          googleTtsStylePrompt: 'Warm whisper',
          googleSttModel: 'gemini-2.5-flash-lite',
          timeoutSeconds: 45,
        ),
      );
      first.close();

      final reopened = await openStore(directory: tempDir.path);
      final stored = reopened.box<AppSettings>().getAll().single;
      final profile = reopened.box<AiProviderProfile>().getAll().single;
      final speech = reopened.box<CloudSpeechConfig>().getAll().single;

      expect(stored.theme, AppThemeSetting.system);
      expect(stored.themeIndex, 2);
      expect(stored.themeStyle, AppThemeStyle.romantic);
      expect(stored.themeStyleIndex, 1);
      expect(stored.language, AppLanguage.english);
      expect(stored.languageIndex, 1);
      expect(stored.aiMode, AiMode.cloud);
      expect(stored.aiModeIndex, 1);
      expect(stored.ttsEnabled, isTrue);
      expect(stored.ttsAutoPlay, isTrue);
      expect(stored.ttsBackend, 'elevenlabs');
      expect(stored.sttBackend, 'openai');
      expect(stored.ttsModel, 'qwen3');
      expect(stored.sttModel, 'moonshine');
      expect(stored.notificationMorningEnabled, isTrue);
      expect(stored.notificationMorningTime, '06:45');
      expect(stored.notificationCheckinEnabled, isTrue);
      expect(stored.notificationCheckinHours, 12);
      expect(stored.modelVariant, 'model-kustom.litertlm');
      expect(stored.modelSource, 'file');
      expect(stored.modelUrl, 'https://example.com/model.litertlm');
      expect(stored.activeCloudProfileId, 42);
      expect(stored.isAgeVerified, isTrue);
      expect(stored.isOnboardingDone, isTrue);
      expect(stored.isPersonaSetup, isTrue);
      expect(stored.conversationSummary, summary);
      expect(stored.summaryMessageCount, 30);

      expect(profile.profileKey, 'openrouter_1');
      expect(profile.providerType, LlmProviderType.openai);
      expect(profile.baseUrl, 'https://openrouter.ai/api/v1');
      expect(profile.stripStreamOptions, isTrue);
      expect(profile.temperature, 1.15);
      expect(profile.topP, 0.92);
      expect(profile.topK, 40);
      expect(profile.maxOutputTokens, 4096);
      expect(profile.presencePenalty, 0.4);
      expect(profile.frequencyPenalty, -0.2);
      expect(profile.stopSequences, const ['END', '###']);
      expect(profile.seed, 12345);
      expect(profile.reasoningEffort, 'medium');
      expect(profile.thinkingBudgetTokens, 2048);
      expect(profile.geminiSafetyLevel, 'block_only_high');
      expect(profile.maxHistoryMessages, 120);
      expect(profile.maxMemoryFacts, 80);
      expect(profile.maxInputChars, 32000);
      expect(profile.maxPromptChars, 128000);
      expect(profile.enforceShortReply, isTrue);
      expect(profile.customSystemPrompt, 'Always speak poetically.');
      expect(profile.timeoutSeconds, 90);
      expect(profile.enableBackgroundTasks, isFalse);
      expect(profile.backgroundModelId, 'google/gemini-2.5-flash-lite');

      expect(speech.elevenLabsVoiceId, 'voice_123');
      expect(speech.elevenLabsStability, 0.35);
      expect(speech.elevenLabsSttTagAudioEvents, isTrue);
      expect(speech.openaiTtsVoice, 'nova');
      expect(speech.openaiSttModel, 'whisper-large-v3-turbo');
      expect(speech.googleTtsVoiceName, 'Zephyr');
      expect(speech.timeoutSeconds, 45);
      reopened.close();
    }, skip: libDir == null && !isCi ? 'Library native ObjectBox tidak tersedia di host' : false);

    test('baris lama tanpa nilai baru dinormalkan', () {
      final legacy = AppSettings()
        ..ttsBackend = ''
        ..sttBackend = 'aneh'
        ..ttsModel = 'tidak-ada'
        ..notificationMorningTime = '99:99'
        ..notificationCheckinHours = 0
        ..modelSource = 'sideload'
        ..themeIndex = 99
        ..themeStyleIndex = 99
        ..languageIndex = -4;

      final fixed = legacy.normalized();

      expect(fixed.ttsBackend, 'system');
      expect(fixed.sttBackend, 'system');
      expect(fixed.ttsModel, 'inflect');
      expect(fixed.notificationMorningTime, '08:00');
      expect(fixed.notificationCheckinHours, 6);
      expect(fixed.modelSource, '');
      expect(fixed.themeIndex, AppThemeSetting.values.length - 1);
      expect(fixed.themeStyleIndex, AppThemeStyle.values.length - 1);
      expect(fixed.languageIndex, 0);
      // Getter tidak boleh melempar RangeError untuk index rusak.
      expect(legacy.theme, AppThemeSetting.values.last);
      expect(legacy.themeStyle, AppThemeStyle.values.last);
      expect(legacy.language, AppLanguage.indonesian);
    });

    test('modelVariant kosong dipertahankan (belum memilih model)', () {
      expect(AppSettings().normalized().modelVariant, '');
    });
  });
}
