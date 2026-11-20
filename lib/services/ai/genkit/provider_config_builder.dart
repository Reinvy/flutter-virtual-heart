// Pure helper — normalisasi URL, builder opsi Genkit per provider, dan sanitasi parameter.
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:genkit_openai/genkit_openai.dart';

import '../../../models/ai_provider_profile.dart';
import '../../../models/cloud_speech_config.dart';

/// Kategori bahaya yang dipetakan saat pengguna memilih threshold safety Gemini.
const _kGeminiHarmCategories = <String>[
  'HARM_CATEGORY_HATE_SPEECH',
  'HARM_CATEGORY_SEXUALLY_EXPLICIT',
  'HARM_CATEGORY_HARASSMENT',
  'HARM_CATEGORY_DANGEROUS_CONTENT',
  'HARM_CATEGORY_CIVIC_INTEGRITY',
];

const _kAnthropicEffortLevels = {'low', 'medium', 'high', 'xhigh', 'max'};
const _kOpenAiReasoningEfforts = {
  'none',
  'minimal',
  'low',
  'medium',
  'high',
  'xhigh',
  'max',
};
const _kGeminiThinkingLevels = {'MINIMAL', 'LOW', 'MEDIUM', 'HIGH'};

/// Menormalkan base URL kustom: trim spasi dan hapus trailing slash berlebih.
/// Mengembalikan `null` jika kosong.
String? normalizeBaseUrl(String raw) {
  var trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  while (trimmed.endsWith('/') && trimmed.length > 8) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

/// Menormalkan base URL khusus Anthropic (`anthropic_sdk_dart` selalu
/// menambahkan `/v1/messages`, sehingga akhiran `/v1` dari pengguna dipangkas).
String? normalizeAnthropicBaseUrl(String raw) {
  final normalized = normalizeBaseUrl(raw);
  if (normalized == null) return null;
  if (normalized.endsWith('/v1')) {
    return normalized.substring(0, normalized.length - 3);
  }
  return normalized;
}

/// Menormalkan base URL khusus Google Gemini (`genkit_google_genai` selalu
/// menambahkan `/v1beta/...`, sehingga akhiran `/v1beta` atau `/v1` dipangkas).
String? normalizeGoogleBaseUrl(String raw) {
  final normalized = normalizeBaseUrl(raw);
  if (normalized == null) return null;
  if (normalized.endsWith('/v1beta')) {
    return normalized.substring(0, normalized.length - 7);
  }
  if (normalized.endsWith('/v1')) {
    return normalized.substring(0, normalized.length - 3);
  }
  return normalized;
}

/// Memvalidasi base URL kustom: kosong dianggap valid (pakai default resmi),
/// selain itu wajib skema `http`/`https` dengan host tidak kosong.
bool isValidBaseUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return true;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  return uri.host.isNotEmpty;
}

/// Mengonversi kode bahasa BCP-47 (mis. `id-ID`, `en-US`) menjadi ISO-639-1 (`id`, `en`).
String? iso6391Language(String? languageCode) {
  final trimmed = languageCode?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final sep = trimmed.contains('-')
      ? '-'
      : (trimmed.contains('_') ? '_' : null);
  final primary = sep == null ? trimmed : trimmed.split(sep).first;
  return primary.toLowerCase();
}

/// Membangun [GeminiOptions] ter-sanitasi dari [AiProviderProfile].
GeminiOptions buildGeminiOptions(
  AiProviderProfile profile, {
  int? maxOutputTokensOverride,
  double? temperatureOverride,
  bool disableThinking = false,
}) {
  final p = profile.normalized();
  final temp = (temperatureOverride ?? p.temperature)?.clamp(0.0, 2.0).toDouble();
  final maxOut = maxOutputTokensOverride ?? (p.maxOutputTokens > 0 ? p.maxOutputTokens : null);

  GeminiThinkingConfig? thinkingConfig;
  if (!disableThinking) {
    final effortUpper = p.reasoningEffort.toUpperCase();
    if (p.thinkingBudgetTokens != null) {
      thinkingConfig = GeminiThinkingConfig(
        thinkingBudget: p.thinkingBudgetTokens!.clamp(0, 24576),
        includeThoughts: false,
      );
    } else if (_kGeminiThinkingLevels.contains(effortUpper)) {
      thinkingConfig = GeminiThinkingConfig(
        thinkingLevel: effortUpper,
        includeThoughts: false,
      );
    } else if (p.reasoningEffort == 'none') {
      thinkingConfig = GeminiThinkingConfig(
        thinkingBudget: 0,
        includeThoughts: false,
      );
    }
  }

  List<GeminiSafetySettings>? safetySettings;
  if (p.geminiSafetyLevel == 'block_only_high') {
    safetySettings = [
      for (final cat in _kGeminiHarmCategories)
        GeminiSafetySettings(category: cat, threshold: 'BLOCK_ONLY_HIGH'),
    ];
  } else if (p.geminiSafetyLevel == 'block_none') {
    safetySettings = [
      for (final cat in _kGeminiHarmCategories)
        GeminiSafetySettings(category: cat, threshold: 'BLOCK_NONE'),
    ];
  }

  return GeminiOptions(
    temperature: temp,
    topP: p.topP,
    topK: p.topK,
    maxOutputTokens: maxOut,
    presencePenalty: p.presencePenalty,
    frequencyPenalty: p.frequencyPenalty,
    stopSequences: p.stopSequences.isNotEmpty ? p.stopSequences : null,
    seed: p.seed,
    thinkingConfig: thinkingConfig,
    safetySettings: safetySettings,
  );
}

/// Membangun [AnthropicOptions] ter-sanitasi dari [AiProviderProfile].
///
/// Menegakkan aturan keras Anthropic API:
/// 1. `temperature` di-clamp ke `0.0..1.0`.
/// 2. `temperature` dan `topP` tidak pernah dikirim bersamaan (Claude 4.5+
///    mengembalikan HTTP 400 bila keduanya ada).
/// 3. Bila extended thinking aktif (`enabled` / `adaptive`), `temperature`,
///    `topP`, dan `topK` dihilangkan, serta `maxTokens` dijamin > `budgetTokens`.
AnthropicOptions buildAnthropicOptions(
  AiProviderProfile profile, {
  int? maxOutputTokensOverride,
  double? temperatureOverride,
  bool disableThinking = false,
}) {
  final p = profile.normalized();
  var maxTokens = maxOutputTokensOverride ?? (p.maxOutputTokens > 0 ? p.maxOutputTokens : 2048);

  AnthropicThinkingConfig? thinking;
  AnthropicOutputConfig? outputConfig;

  if (!disableThinking) {
    if (p.thinkingBudgetTokens != null && p.thinkingBudgetTokens! >= 1024) {
      final budget = p.thinkingBudgetTokens!.clamp(1024, 32768);
      thinking = AnthropicThinkingConfig(type: 'enabled', budgetTokens: budget);
      if (maxTokens <= budget) {
        maxTokens = (budget + 1024).clamp(2048, 65536);
      }
    } else if (p.reasoningEffort == 'adaptive') {
      thinking = AnthropicThinkingConfig(type: 'adaptive');
    } else if (p.reasoningEffort == 'none') {
      thinking = AnthropicThinkingConfig(type: 'disabled');
    }

    if (_kAnthropicEffortLevels.contains(p.reasoningEffort)) {
      outputConfig = AnthropicOutputConfig(effort: p.reasoningEffort);
    }
  }

  final thinkingActive =
      thinking != null && (thinking.type == 'enabled' || thinking.type == 'adaptive');

  double? temperature;
  double? topP;
  int? topK;
  if (!thinkingActive) {
    final rawTemp = temperatureOverride ?? p.temperature;
    if (rawTemp != null) {
      temperature = rawTemp.clamp(0.0, 1.0).toDouble();
      // Jangan kirim topP bersamaan dengan temperature pada Anthropic API.
      topP = null;
    } else {
      topP = p.topP;
    }
    topK = p.topK;
  }

  return AnthropicOptions(
    maxTokens: maxTokens,
    temperature: temperature,
    topP: topP,
    topK: topK,
    stopSequences: p.stopSequences.isNotEmpty ? p.stopSequences : null,
    thinking: thinking,
    outputConfig: outputConfig,
  );
}

/// Membangun [OpenAIChatOptions] ter-sanitasi dari [AiProviderProfile].
OpenAIChatOptions buildOpenAIOptions(
  AiProviderProfile profile, {
  int? maxOutputTokensOverride,
  double? temperatureOverride,
  bool disableReasoning = false,
}) {
  final p = profile.normalized();
  final temp = (temperatureOverride ?? p.temperature)?.clamp(0.0, 2.0).toDouble();
  final maxTokens = maxOutputTokensOverride ?? (p.maxOutputTokens > 0 ? p.maxOutputTokens : null);
  final reasoning = !disableReasoning && _kOpenAiReasoningEfforts.contains(p.reasoningEffort)
      ? p.reasoningEffort
      : null;

  return OpenAIChatOptions(
    temperature: temp,
    topP: p.topP,
    maxTokens: maxTokens,
    presencePenalty: p.presencePenalty,
    frequencyPenalty: p.frequencyPenalty,
    stop: p.stopSequences.isNotEmpty ? p.stopSequences : null,
    seed: p.seed,
    reasoningEffort: reasoning,
  );
}

/// Membangun [OpenAISpeechOptions] dari [CloudSpeechConfig].
OpenAISpeechOptions buildOpenAiSpeechOptions(CloudSpeechConfig config) {
  final c = config.normalized();
  final instructions =
      c.openaiTtsInstructions.isNotEmpty && c.openaiTtsModel.contains('gpt-4o')
      ? c.openaiTtsInstructions
      : null;
  return OpenAISpeechOptions(
    voice: c.openaiTtsVoice,
    speed: c.openaiTtsSpeed,
    instructions: instructions,
    responseFormat: c.openaiTtsFormat,
  );
}

/// Membangun [OpenAITranscriptionOptions] dari [CloudSpeechConfig].
OpenAITranscriptionOptions buildOpenAiTranscriptionOptions(
  CloudSpeechConfig config, {
  String? languageCode,
}) {
  final c = config.normalized();
  return OpenAITranscriptionOptions(
    language: iso6391Language(languageCode),
    prompt: c.openaiSttPrompt.isNotEmpty ? c.openaiSttPrompt : null,
    temperature: c.openaiSttTemperature,
  );
}

/// Membangun [GeminiTtsOptions] dari [CloudSpeechConfig].
GeminiTtsOptions buildGeminiTtsOptions(CloudSpeechConfig config) {
  final c = config.normalized();
  return GeminiTtsOptions(
    responseModalities: const ['AUDIO'],
    speechConfig: GeminiSpeechConfig(
      voiceConfig: GeminiVoiceConfig(
        prebuiltVoiceConfig: GeminiPrebuiltVoiceConfig(
          voiceName: c.googleTtsVoiceName,
        ),
      ),
    ),
  );
}
