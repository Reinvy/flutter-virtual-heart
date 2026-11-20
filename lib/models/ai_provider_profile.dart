// Entity ObjectBox — Profil provider Cloud AI (BYOK) + parameter generasi & konteks.
import 'dart:convert';

import 'package:objectbox/objectbox.dart';

/// Jenis protokol API LLM Cloud yang didukung lewat Genkit.
enum LlmProviderType { google, anthropic, openai }

/// Profil konfigurasi satu provider Cloud LLM BYOK.
///
/// API key **tidak** disimpan di entity ini (disimpan terenkripsi di
/// `SecretStore` dengan kunci `vh_llm_key_<profileKey>`).
@Entity()
class AiProviderProfile {
  @Id()
  int id = 0;

  /// Kunci stabil untuk mengikat API key di `SecretStore`.
  String profileKey = '';

  /// Nama profil tampilan pengguna (mis. "Google Gemini", "OpenRouter").
  String name = '';

  /// Backing field untuk [providerType].
  int providerTypeIndex = 0;

  /// ID preset awal (`google`, `anthropic`, `openai`, `openrouter`, `groq`,
  /// `deepseek`, `xai`, `together`, `ollama`, `custom`).
  String presetId = 'custom';

  /// Base URL kustom (kosong = endpoint resmi provider).
  String baseUrl = '';

  /// Identitas model target (mis. `gemini-2.5-flash`, `claude-sonnet-4-6`, `gpt-4o`).
  String modelId = '';

  /// JSON object string berisi header HTTP tambahan opsional.
  String customHeadersJson = '';

  /// Menghapus `stream_options` pada request OpenAI-compatible untuk server
  /// pihak ketiga lama yang menolaknya.
  bool stripStreamOptions = false;

  // ── Parameter Generasi ────────────────────────────────────────────────────

  /// Sampling temperature (null = default provider; 0..2 Google/OpenAI, 0..1 Anthropic).
  double? temperature;

  /// Nucleus sampling top-P (null = default provider; 0..1).
  double? topP;

  /// Top-K sampling (null = default provider; Google & Anthropic).
  int? topK;

  /// Batas token output maksimum (`0` = default provider; 128..32768).
  int maxOutputTokens = 2048;

  /// Presence penalty (-2.0..2.0; OpenAI & Google).
  double? presencePenalty;

  /// Frequency penalty (-2.0..2.0; OpenAI & Google).
  double? frequencyPenalty;

  /// Daftar stop sequences opsional.
  List<String> stopSequences = const [];

  /// Seed deterministik opsional (OpenAI & Google).
  int? seed;

  /// Level reasoning/thinking (`''` | `none` | `minimal` | `low` | `medium` |
  /// `high` | `xhigh` | `max` | `adaptive`).
  String reasoningEffort = '';

  /// Anggaran token thinking opsional (Anthropic ≥1024 / Gemini 0..24576).
  int? thinkingBudgetTokens;

  /// Threshold safety bawaan Gemini (`default` | `block_only_high` | `block_none`).
  String geminiSafetyLevel = 'default';

  // ── Parameter Kebebasan Konteks & Prompt ─────────────────────────────────

  /// Jumlah maksimum pesan riwayat yang disertakan ke model (10..200).
  int maxHistoryMessages = 60;

  /// Jumlah maksimum fakta memori di system prompt (5..100).
  int maxMemoryFacts = 40;

  /// Batas panjang input pengguna per pesan dalam karakter (2000..64000).
  int maxInputChars = 12000;

  /// Anggaran karakter total prompt/riwayat cloud (6000..256000).
  int maxPromptChars = 48000;

  /// Bila `true`, instruksi "1–3 paragraf singkat" tetap dimasukkan ke prompt.
  /// Default `false` di cloud agar model bebas merespons lebih kaya & alami.
  bool enforceShortReply = false;

  /// Instruksi sistem tambahan opsional dari pengguna.
  String customSystemPrompt = '';

  /// Batas waktu tunggu request dalam detik (15..300).
  int timeoutSeconds = 60;

  /// Apakah ekstraksi memori & ringkasan otomatis dijalankan memakai profil ini.
  bool enableBackgroundTasks = true;

  /// Model opsional yang lebih cepat/murah di provider yang sama untuk memori & ringkasan.
  String backgroundModelId = '';

  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  LlmProviderType get providerType =>
      _enumAt(LlmProviderType.values, providerTypeIndex);
  set providerType(LlmProviderType value) => providerTypeIndex = value.index;

  static const Set<String> validReasoningEfforts = {
    '',
    'none',
    'minimal',
    'low',
    'medium',
    'high',
    'xhigh',
    'max',
    'adaptive',
  };

  static const Set<String> validGeminiSafetyLevels = {
    'default',
    'block_only_high',
    'block_none',
  };

  AiProviderProfile({
    this.id = 0,
    this.profileKey = '',
    this.name = '',
    LlmProviderType providerType = LlmProviderType.google,
    this.presetId = 'custom',
    this.baseUrl = '',
    this.modelId = '',
    this.customHeadersJson = '',
    this.stripStreamOptions = false,
    this.temperature = 0.9,
    this.topP,
    this.topK,
    this.maxOutputTokens = 2048,
    this.presencePenalty,
    this.frequencyPenalty,
    this.stopSequences = const [],
    this.seed,
    this.reasoningEffort = '',
    this.thinkingBudgetTokens,
    this.geminiSafetyLevel = 'default',
    this.maxHistoryMessages = 60,
    this.maxMemoryFacts = 40,
    this.maxInputChars = 12000,
    this.maxPromptChars = 48000,
    this.enforceShortReply = false,
    this.customSystemPrompt = '',
    this.timeoutSeconds = 60,
    this.enableBackgroundTasks = true,
    this.backgroundModelId = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    providerTypeIndex = providerType.index;
  }

  /// Mengembalikan salinan dengan field tertentu ditimpa.
  ///
  /// Gunakan flag `clear*` untuk mengembalikan parameter nullable ke `null`.
  AiProviderProfile copyWith({
    String? profileKey,
    String? name,
    LlmProviderType? providerType,
    String? presetId,
    String? baseUrl,
    String? modelId,
    String? customHeadersJson,
    bool? stripStreamOptions,
    double? temperature,
    bool clearTemperature = false,
    double? topP,
    bool clearTopP = false,
    int? topK,
    bool clearTopK = false,
    int? maxOutputTokens,
    double? presencePenalty,
    bool clearPresencePenalty = false,
    double? frequencyPenalty,
    bool clearFrequencyPenalty = false,
    List<String>? stopSequences,
    int? seed,
    bool clearSeed = false,
    String? reasoningEffort,
    int? thinkingBudgetTokens,
    bool clearThinkingBudgetTokens = false,
    String? geminiSafetyLevel,
    int? maxHistoryMessages,
    int? maxMemoryFacts,
    int? maxInputChars,
    int? maxPromptChars,
    bool? enforceShortReply,
    String? customSystemPrompt,
    int? timeoutSeconds,
    bool? enableBackgroundTasks,
    String? backgroundModelId,
    DateTime? createdAt,
  }) {
    return AiProviderProfile(
      id: id,
      profileKey: profileKey ?? this.profileKey,
      name: name ?? this.name,
      providerType: providerType ?? this.providerType,
      presetId: presetId ?? this.presetId,
      baseUrl: baseUrl ?? this.baseUrl,
      modelId: modelId ?? this.modelId,
      customHeadersJson: customHeadersJson ?? this.customHeadersJson,
      stripStreamOptions: stripStreamOptions ?? this.stripStreamOptions,
      temperature: clearTemperature ? null : (temperature ?? this.temperature),
      topP: clearTopP ? null : (topP ?? this.topP),
      topK: clearTopK ? null : (topK ?? this.topK),
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      presencePenalty: clearPresencePenalty
          ? null
          : (presencePenalty ?? this.presencePenalty),
      frequencyPenalty: clearFrequencyPenalty
          ? null
          : (frequencyPenalty ?? this.frequencyPenalty),
      stopSequences: stopSequences ?? List<String>.of(this.stopSequences),
      seed: clearSeed ? null : (seed ?? this.seed),
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      thinkingBudgetTokens: clearThinkingBudgetTokens
          ? null
          : (thinkingBudgetTokens ?? this.thinkingBudgetTokens),
      geminiSafetyLevel: geminiSafetyLevel ?? this.geminiSafetyLevel,
      maxHistoryMessages: maxHistoryMessages ?? this.maxHistoryMessages,
      maxMemoryFacts: maxMemoryFacts ?? this.maxMemoryFacts,
      maxInputChars: maxInputChars ?? this.maxInputChars,
      maxPromptChars: maxPromptChars ?? this.maxPromptChars,
      enforceShortReply: enforceShortReply ?? this.enforceShortReply,
      customSystemPrompt: customSystemPrompt ?? this.customSystemPrompt,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      enableBackgroundTasks:
          enableBackgroundTasks ?? this.enableBackgroundTasks,
      backgroundModelId: backgroundModelId ?? this.backgroundModelId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Menormalkan nilai yang berada di luar rentang aman.
  AiProviderProfile normalized() {
    final safeType = _enumAt(LlmProviderType.values, providerTypeIndex);
    final maxTemp = safeType == LlmProviderType.anthropic ? 1.0 : 2.0;
    final cleanTemp = temperature?.clamp(0.0, maxTemp).toDouble();
    final cleanTopP = topP?.clamp(0.0, 1.0).toDouble();
    final cleanTopK = topK?.clamp(1, 500);
    final cleanMaxOut = maxOutputTokens <= 0
        ? 0
        : maxOutputTokens.clamp(128, 32768);
    final cleanPresence = presencePenalty?.clamp(-2.0, 2.0).toDouble();
    final cleanFrequency = frequencyPenalty?.clamp(-2.0, 2.0).toDouble();
    final cleanBudget = thinkingBudgetTokens?.clamp(0, 65536);

    return copyWith(
      profileKey: profileKey.trim(),
      name: name.trim(),
      providerType: safeType,
      presetId: presetId.trim().isEmpty ? 'custom' : presetId.trim(),
      baseUrl: baseUrl.trim(),
      modelId: modelId.trim(),
      customHeadersJson: customHeadersJson.trim(),
      temperature: cleanTemp,
      clearTemperature: cleanTemp == null,
      topP: cleanTopP,
      clearTopP: cleanTopP == null,
      topK: cleanTopK,
      clearTopK: cleanTopK == null,
      maxOutputTokens: cleanMaxOut,
      presencePenalty: cleanPresence,
      clearPresencePenalty: cleanPresence == null,
      frequencyPenalty: cleanFrequency,
      clearFrequencyPenalty: cleanFrequency == null,
      stopSequences: stopSequences
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(8)
          .toList(),
      reasoningEffort: validReasoningEfforts.contains(reasoningEffort)
          ? reasoningEffort
          : '',
      thinkingBudgetTokens: cleanBudget,
      clearThinkingBudgetTokens: cleanBudget == null,
      geminiSafetyLevel: validGeminiSafetyLevels.contains(geminiSafetyLevel)
          ? geminiSafetyLevel
          : 'default',
      maxHistoryMessages: maxHistoryMessages.clamp(10, 200),
      maxMemoryFacts: maxMemoryFacts.clamp(5, 100),
      maxInputChars: maxInputChars.clamp(2000, 64000),
      maxPromptChars: maxPromptChars.clamp(6000, 256000),
      customSystemPrompt: customSystemPrompt.trim(),
      timeoutSeconds: timeoutSeconds.clamp(15, 300),
      backgroundModelId: backgroundModelId.trim(),
    );
  }

  /// Mem-parse [customHeadersJson] menjadi map header HTTP yang aman.
  /// Mengembalikan map kosong bila string kosong atau bukan JSON object valid.
  Map<String, String> parsedCustomHeaders() {
    final raw = customHeadersJson.trim();
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final result = <String, String>{};
      decoded.forEach((key, value) {
        final k = '$key'.trim();
        final v = value == null ? '' : '$value'.trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          result[k] = v;
        }
      });
      return result;
    } catch (_) {
      return const {};
    }
  }

  /// `true` bila [baseUrl] mengarah ke server lokal/LAN (mis. Ollama/LM Studio)
  /// sehingga API key boleh dikosongkan.
  bool get isLocalNetworkBaseUrl => isLocalNetworkUrl(baseUrl);

  /// Mengecek apakah [url] menunjuk host loopback atau jaringan privat RFC1918.
  static bool isLocalNetworkUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '10.0.2.2' ||
        host.endsWith('.local')) {
      return true;
    }
    if (host.startsWith('10.') || host.startsWith('192.168.')) return true;
    final parts = host.split('.');
    if (parts.length == 4 && parts[0] == '172') {
      final second = int.tryParse(parts[1]);
      if (second != null && second >= 16 && second <= 31) return true;
    }
    return false;
  }

  bool hasSameValues(AiProviderProfile other) {
    if (stopSequences.length != other.stopSequences.length) return false;
    for (var i = 0; i < stopSequences.length; i++) {
      if (stopSequences[i] != other.stopSequences[i]) return false;
    }
    return profileKey == other.profileKey &&
        name == other.name &&
        providerTypeIndex == other.providerTypeIndex &&
        presetId == other.presetId &&
        baseUrl == other.baseUrl &&
        modelId == other.modelId &&
        customHeadersJson == other.customHeadersJson &&
        stripStreamOptions == other.stripStreamOptions &&
        temperature == other.temperature &&
        topP == other.topP &&
        topK == other.topK &&
        maxOutputTokens == other.maxOutputTokens &&
        presencePenalty == other.presencePenalty &&
        frequencyPenalty == other.frequencyPenalty &&
        seed == other.seed &&
        reasoningEffort == other.reasoningEffort &&
        thinkingBudgetTokens == other.thinkingBudgetTokens &&
        geminiSafetyLevel == other.geminiSafetyLevel &&
        maxHistoryMessages == other.maxHistoryMessages &&
        maxMemoryFacts == other.maxMemoryFacts &&
        maxInputChars == other.maxInputChars &&
        maxPromptChars == other.maxPromptChars &&
        enforceShortReply == other.enforceShortReply &&
        customSystemPrompt == other.customSystemPrompt &&
        timeoutSeconds == other.timeoutSeconds &&
        enableBackgroundTasks == other.enableBackgroundTasks &&
        backgroundModelId == other.backgroundModelId;
  }

  static T _enumAt<T>(List<T> values, int index) {
    final safe =
        index < 0 ? 0 : (index >= values.length ? values.length - 1 : index);
    return values[safe];
  }
}
