// Katalog preset Cloud LLM & Cloud Speech (TTS/STT) — data murni tanpa UI/engine.
import '../../models/ai_provider_profile.dart';

/// Preset awal untuk mempermudah pembuatan profil provider Cloud LLM BYOK.
class CloudProviderPreset {
  final String id;
  final String displayName;
  final LlmProviderType providerType;
  final String defaultBaseUrl;
  final String defaultModelId;
  final List<String> suggestedModels;
  final bool requiresBaseUrl;
  final bool allowsEmptyApiKey;
  final String? defaultBackgroundModelId;

  const CloudProviderPreset({
    required this.id,
    required this.displayName,
    required this.providerType,
    this.defaultBaseUrl = '',
    required this.defaultModelId,
    required this.suggestedModels,
    this.requiresBaseUrl = false,
    this.allowsEmptyApiKey = false,
    this.defaultBackgroundModelId,
  });

  /// Membuat [AiProviderProfile] baru siap edit dari preset ini.
  AiProviderProfile toNewProfile({required String profileKey}) {
    return AiProviderProfile(
      profileKey: profileKey,
      name: displayName,
      providerType: providerType,
      presetId: id,
      baseUrl: defaultBaseUrl,
      modelId: defaultModelId,
      backgroundModelId: defaultBackgroundModelId ?? '',
      temperature: providerType == LlmProviderType.anthropic ? 0.8 : 0.9,
      maxOutputTokens: 2048,
      stripStreamOptions: id == 'ollama',
    );
  }
}

/// Katalog preset Cloud LLM yang muncul di quick-add Cloud BYOK.
const kCloudProviderPresets = <CloudProviderPreset>[
  CloudProviderPreset(
    id: 'google',
    displayName: 'Google Gemini',
    providerType: LlmProviderType.google,
    defaultModelId: 'gemini-2.5-flash',
    defaultBackgroundModelId: 'gemini-2.5-flash-lite',
    suggestedModels: [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
    ],
  ),
  CloudProviderPreset(
    id: 'anthropic',
    displayName: 'Anthropic Claude',
    providerType: LlmProviderType.anthropic,
    defaultModelId: 'claude-sonnet-4-6',
    defaultBackgroundModelId: 'claude-haiku-4-5',
    suggestedModels: [
      'claude-sonnet-4-6',
      'claude-haiku-4-5',
      'claude-opus-4-6',
      'claude-sonnet-4-5',
    ],
  ),
  CloudProviderPreset(
    id: 'anthropic_compat',
    displayName: 'Anthropic-Compatible',
    providerType: LlmProviderType.anthropic,
    defaultBaseUrl: 'https://api.example.com',
    defaultModelId: 'claude-sonnet-4-6',
    requiresBaseUrl: true,
    suggestedModels: [
      'claude-sonnet-4-6',
      'claude-haiku-4-5',
      'claude-sonnet-4-5',
    ],
  ),
  CloudProviderPreset(
    id: 'openai',
    displayName: 'OpenAI',
    providerType: LlmProviderType.openai,
    defaultModelId: 'gpt-4o',
    defaultBackgroundModelId: 'gpt-4o-mini',
    suggestedModels: [
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-5',
      'gpt-5-mini',
      'o3-mini',
    ],
  ),
  CloudProviderPreset(
    id: 'openrouter',
    displayName: 'OpenRouter',
    providerType: LlmProviderType.openai,
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
    defaultModelId: 'anthropic/claude-sonnet-4.6',
    defaultBackgroundModelId: 'google/gemini-2.5-flash-lite',
    requiresBaseUrl: true,
    suggestedModels: [
      'anthropic/claude-sonnet-4.6',
      'google/gemini-2.5-flash',
      'openai/gpt-4o-mini',
      'deepseek/deepseek-chat-v3-0324',
    ],
  ),
  CloudProviderPreset(
    id: 'groq',
    displayName: 'Groq',
    providerType: LlmProviderType.openai,
    defaultBaseUrl: 'https://api.groq.com/openai/v1',
    defaultModelId: 'llama-3.3-70b-versatile',
    defaultBackgroundModelId: 'llama-3.1-8b-instant',
    requiresBaseUrl: true,
    suggestedModels: [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'qwen/qwen3-32b',
    ],
  ),
  CloudProviderPreset(
    id: 'deepseek',
    displayName: 'DeepSeek',
    providerType: LlmProviderType.openai,
    defaultBaseUrl: 'https://api.deepseek.com',
    defaultModelId: 'deepseek-chat',
    requiresBaseUrl: true,
    suggestedModels: [
      'deepseek-chat',
      'deepseek-reasoner',
    ],
  ),
  CloudProviderPreset(
    id: 'xai',
    displayName: 'xAI (Grok)',
    providerType: LlmProviderType.openai,
    defaultBaseUrl: 'https://api.x.ai/v1',
    defaultModelId: 'grok-3',
    defaultBackgroundModelId: 'grok-3-mini',
    requiresBaseUrl: true,
    suggestedModels: [
      'grok-3',
      'grok-3-mini',
    ],
  ),
  CloudProviderPreset(
    id: 'together',
    displayName: 'Together AI',
    providerType: LlmProviderType.openai,
    defaultBaseUrl: 'https://api.together.xyz/v1',
    defaultModelId: 'meta-llama/Llama-3.3-70B-Instruct-Turbo',
    requiresBaseUrl: true,
    suggestedModels: [
      'meta-llama/Llama-3.3-70B-Instruct-Turbo',
      'Qwen/Qwen2.5-72B-Instruct-Turbo',
    ],
  ),
  CloudProviderPreset(
    id: 'ollama',
    displayName: 'Ollama / LM Studio',
    providerType: LlmProviderType.openai,
    defaultBaseUrl: 'http://localhost:11434/v1',
    defaultModelId: 'llama3.2',
    requiresBaseUrl: true,
    allowsEmptyApiKey: true,
    suggestedModels: [
      'llama3.2',
      'qwen2.5:7b',
      'gemma3:4b',
    ],
  ),
  CloudProviderPreset(
    id: 'custom_openai',
    displayName: 'OpenAI-Compatible',
    providerType: LlmProviderType.openai,
    defaultBaseUrl: 'https://api.example.com/v1',
    defaultModelId: 'gpt-4o-mini',
    requiresBaseUrl: true,
    suggestedModels: [
      'gpt-4o-mini',
      'gpt-4o',
    ],
  ),
];

/// Cari preset berdasarkan [id], atau kembalikan null bila tidak dikenal.
CloudProviderPreset? cloudPresetById(String id) {
  for (final preset in kCloudProviderPresets) {
    if (preset.id == id) return preset;
  }
  return null;
}

/// Saran model default berdasarkan [LlmProviderType].
List<String> suggestedModelsForType(LlmProviderType type) => switch (type) {
  LlmProviderType.google => kCloudProviderPresets[0].suggestedModels,
  LlmProviderType.anthropic => kCloudProviderPresets[1].suggestedModels,
  LlmProviderType.openai => kCloudProviderPresets[3].suggestedModels,
};

// ── Katalog Cloud Speech (TTS & STT) ─────────────────────────────────────────

/// Opsi suara preset ElevenLabs yang langsung tersedia tanpa fetch `/voices`.
class ElevenLabsVoicePreset {
  final String voiceId;
  final String name;
  final String styleTag;

  const ElevenLabsVoicePreset({
    required this.voiceId,
    required this.name,
    required this.styleTag,
  });
}

const kElevenLabsVoicePresets = <ElevenLabsVoicePreset>[
  ElevenLabsVoicePreset(
    voiceId: 'EXAVITQu4vr4xnSDxMaL',
    name: 'Sarah',
    styleTag: 'Warm, soft (F)',
  ),
  ElevenLabsVoicePreset(
    voiceId: '21m00Tcm4TlvDq8ikWAM',
    name: 'Rachel',
    styleTag: 'Calm, clear (F)',
  ),
  ElevenLabsVoicePreset(
    voiceId: '9BWtsMINqrJLrRacOk9x',
    name: 'Aria',
    styleTag: 'Expressive (F)',
  ),
  ElevenLabsVoicePreset(
    voiceId: 'XB0fDUnXU5powFXDhCwa',
    name: 'Charlotte',
    styleTag: 'Gentle, intimate (F)',
  ),
  ElevenLabsVoicePreset(
    voiceId: 'ErXwobaYiN019PkySvjV',
    name: 'Antoni',
    styleTag: 'Well-rounded (M)',
  ),
  ElevenLabsVoicePreset(
    voiceId: 'pNInz6obpgDQGcFmaJgB',
    name: 'Adam',
    styleTag: 'Deep, calm (M)',
  ),
  ElevenLabsVoicePreset(
    voiceId: 'TxGEqnHWrfWFTfGW9XjX',
    name: 'Josh',
    styleTag: 'Young, warm (M)',
  ),
  ElevenLabsVoicePreset(
    voiceId: 'onwK4e9ZLuTAKqWW03F9',
    name: 'Daniel',
    styleTag: 'Deep, steady (M)',
  ),
];

const kElevenLabsTtsModels = <String>[
  'eleven_multilingual_v2',
  'eleven_flash_v2_5',
  'eleven_turbo_v2_5',
  'eleven_v3',
];

const kElevenLabsOutputFormats = <String>[
  'mp3_44100_128',
  'mp3_44100_64',
  'mp3_22050_32',
  'pcm_24000',
];

const kElevenLabsSttModels = <String>[
  'scribe_v2',
  'scribe_v1',
];

const kOpenAiTtsModels = <String>[
  'gpt-4o-mini-tts',
  'tts-1',
  'tts-1-hd',
];

const kOpenAiTtsVoices = <String>[
  'coral',
  'alloy',
  'ash',
  'ballad',
  'echo',
  'fable',
  'nova',
  'onyx',
  'sage',
  'shimmer',
  'verse',
];

const kOpenAiTtsFormats = <String>[
  'mp3',
  'wav',
  'opus',
  'aac',
];

const kOpenAiSttModels = <String>[
  'gpt-4o-mini-transcribe',
  'gpt-4o-transcribe',
  'whisper-1',
  'whisper-large-v3-turbo',
];

const kGroqOpenAiBaseUrl = 'https://api.groq.com/openai/v1';

const kGoogleTtsModels = <String>[
  'gemini-2.5-flash-preview-tts',
  'gemini-2.5-pro-preview-tts',
];

const kGoogleTtsVoices = <String>[
  'Aoede',
  'Zephyr',
  'Kore',
  'Leda',
  'Puck',
  'Charon',
  'Fenrir',
  'Orus',
  'Callirrhoe',
  'Autonoe',
  'Enceladus',
  'Iapetus',
  'Umbriel',
  'Algieba',
  'Despina',
  'Erinome',
  'Algenib',
  'Rasalgethi',
  'Laomedeia',
  'Achernar',
  'Alnilam',
  'Schedar',
  'Gacrux',
  'Pulcherrima',
  'Achird',
  'Zubenelgenubi',
  'Vindemiatrix',
  'Sadachbia',
  'Sadaltager',
  'Sulafat',
];

const kGoogleSttModels = <String>[
  'gemini-2.5-flash',
  'gemini-2.5-flash-lite',
];
