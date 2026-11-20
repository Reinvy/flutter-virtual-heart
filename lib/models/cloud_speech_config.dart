// Entity ObjectBox — Konfigurasi & parameter Cloud TTS dan Cloud STT (BYOK).
import 'package:objectbox/objectbox.dart';

/// Konfigurasi single-row untuk seluruh penyedia suara cloud (ElevenLabs,
/// OpenAI/OpenAI-Compatible, dan Google Gemini).
///
/// Seluruh API key disimpan terpisah di `SecretStore` (bukan di ObjectBox).
@Entity()
class CloudSpeechConfig {
  @Id()
  int id = 0;

  // ── ElevenLabs TTS & STT ─────────────────────────────────────────────────

  /// Base URL opsional (kosong = `https://api.elevenlabs.io/v1`).
  String elevenLabsBaseUrl = '';

  /// Voice ID aktif untuk sintesis ElevenLabs.
  String elevenLabsVoiceId = 'EXAVITQu4vr4xnSDxMaL';

  /// Nama tampilan suara ElevenLabs terpilih.
  String elevenLabsVoiceName = 'Sarah';

  /// Model TTS ElevenLabs (`eleven_multilingual_v2`, `eleven_flash_v2_5`,
  /// `eleven_turbo_v2_5`, `eleven_v3`, atau model kustom).
  String elevenLabsTtsModel = 'eleven_multilingual_v2';

  /// Stabilitas suara (0.0–1.0). Lebih rendah = lebih ekspresif.
  double elevenLabsStability = 0.5;

  /// Kemiripan ke suara referensi (0.0–1.0).
  double elevenLabsSimilarityBoost = 0.75;

  /// Eksagerasi gaya penyampaian (0.0–1.0).
  double elevenLabsStyle = 0.0;

  /// Kecepatan bicara (0.7–1.2 untuk stabilitas percakapan, hingga 4.0).
  double elevenLabsSpeed = 1.0;

  /// Peningkatan kejernihan speaker (`use_speaker_boost`).
  bool elevenLabsUseSpeakerBoost = true;

  /// Format audio output (`mp3_44100_128` kompatibel Free & Paid tier).
  String elevenLabsOutputFormat = 'mp3_44100_128';

  /// Model STT Scribe ElevenLabs (`scribe_v2` | `scribe_v1` | kustom).
  String elevenLabsSttModel = 'scribe_v2';

  /// Tandai kejadian non-ucapan seperti tawa/tepuk tangan (`tag_audio_events`).
  bool elevenLabsSttTagAudioEvents = false;

  /// Pemisahan pembicara (`diarize`).
  bool elevenLabsSttDiarize = false;

  // ── OpenAI / OpenAI-Compatible TTS & STT ─────────────────────────────────

  /// Pakai ulang API key dari profil LLM OpenAI bila tersedia.
  bool openaiTtsReuseLlmKey = true;

  /// Base URL opsional TTS (kosong = `https://api.openai.com/v1`).
  String openaiTtsBaseUrl = '';

  /// Model TTS OpenAI (`gpt-4o-mini-tts`, `tts-1`, `tts-1-hd`, kustom).
  String openaiTtsModel = 'gpt-4o-mini-tts';

  /// Nama suara OpenAI (`coral`, `alloy`, `nova`, `sage`, dll.).
  String openaiTtsVoice = 'coral';

  /// Kecepatan bicara OpenAI (0.25–4.0).
  double openaiTtsSpeed = 1.0;

  /// Instruksi gaya/nada untuk `gpt-4o-mini-tts`.
  String openaiTtsInstructions = '';

  /// Format container audio (`mp3`, `wav`, `opus`, `aac`).
  String openaiTtsFormat = 'mp3';

  /// Pakai ulang API key dari profil LLM OpenAI untuk STT.
  bool openaiSttReuseLlmKey = true;

  /// Base URL opsional STT (mis. `https://api.groq.com/openai/v1` untuk Groq Whisper).
  String openaiSttBaseUrl = '';

  /// Model STT OpenAI/Compatible (`gpt-4o-mini-transcribe`, `gpt-4o-transcribe`,
  /// `whisper-1`, `whisper-large-v3-turbo`, kustom).
  String openaiSttModel = 'gpt-4o-mini-transcribe';

  /// Petunjuk kosakata/konteks opsional untuk STT.
  String openaiSttPrompt = '';

  /// Temperature dekoding STT (0.0–1.0).
  double openaiSttTemperature = 0.0;

  // ── Google Gemini TTS & STT ──────────────────────────────────────────────

  /// Pakai ulang API key dari profil LLM Google bila tersedia.
  bool googleSpeechReuseLlmKey = true;

  /// Base URL opsional Gemini API.
  String googleSpeechBaseUrl = '';

  /// Model TTS Gemini (`gemini-2.5-flash-preview-tts`, `gemini-2.5-pro-preview-tts`).
  String googleTtsModel = 'gemini-2.5-flash-preview-tts';

  /// Prebuilt voice Gemini (`Aoede`, `Zephyr`, `Kore`, `Fenrir`, dll.).
  String googleTtsVoiceName = 'Aoede';

  /// Instruksi gaya suara Gemini TTS opsional.
  String googleTtsStylePrompt = '';

  /// Model STT Gemini multimodal (`gemini-2.5-flash`, `gemini-2.5-flash-lite`).
  String googleSttModel = 'gemini-2.5-flash';

  // ── Umum ─────────────────────────────────────────────────────────────────

  /// Batas waktu tunggu request suara cloud dalam detik (10..120).
  int timeoutSeconds = 30;

  static const Set<String> validElevenLabsFormats = {
    'mp3_44100_128',
    'mp3_44100_64',
    'mp3_22050_32',
    'pcm_24000',
  };

  static const Set<String> validOpenAiTtsFormats = {'mp3', 'wav', 'opus', 'aac'};

  CloudSpeechConfig({
    this.id = 0,
    this.elevenLabsBaseUrl = '',
    this.elevenLabsVoiceId = 'EXAVITQu4vr4xnSDxMaL',
    this.elevenLabsVoiceName = 'Sarah',
    this.elevenLabsTtsModel = 'eleven_multilingual_v2',
    this.elevenLabsStability = 0.5,
    this.elevenLabsSimilarityBoost = 0.75,
    this.elevenLabsStyle = 0.0,
    this.elevenLabsSpeed = 1.0,
    this.elevenLabsUseSpeakerBoost = true,
    this.elevenLabsOutputFormat = 'mp3_44100_128',
    this.elevenLabsSttModel = 'scribe_v2',
    this.elevenLabsSttTagAudioEvents = false,
    this.elevenLabsSttDiarize = false,
    this.openaiTtsReuseLlmKey = true,
    this.openaiTtsBaseUrl = '',
    this.openaiTtsModel = 'gpt-4o-mini-tts',
    this.openaiTtsVoice = 'coral',
    this.openaiTtsSpeed = 1.0,
    this.openaiTtsInstructions = '',
    this.openaiTtsFormat = 'mp3',
    this.openaiSttReuseLlmKey = true,
    this.openaiSttBaseUrl = '',
    this.openaiSttModel = 'gpt-4o-mini-transcribe',
    this.openaiSttPrompt = '',
    this.openaiSttTemperature = 0.0,
    this.googleSpeechReuseLlmKey = true,
    this.googleSpeechBaseUrl = '',
    this.googleTtsModel = 'gemini-2.5-flash-preview-tts',
    this.googleTtsVoiceName = 'Aoede',
    this.googleTtsStylePrompt = '',
    this.googleSttModel = 'gemini-2.5-flash',
    this.timeoutSeconds = 30,
  });

  CloudSpeechConfig copyWith({
    String? elevenLabsBaseUrl,
    String? elevenLabsVoiceId,
    String? elevenLabsVoiceName,
    String? elevenLabsTtsModel,
    double? elevenLabsStability,
    double? elevenLabsSimilarityBoost,
    double? elevenLabsStyle,
    double? elevenLabsSpeed,
    bool? elevenLabsUseSpeakerBoost,
    String? elevenLabsOutputFormat,
    String? elevenLabsSttModel,
    bool? elevenLabsSttTagAudioEvents,
    bool? elevenLabsSttDiarize,
    bool? openaiTtsReuseLlmKey,
    String? openaiTtsBaseUrl,
    String? openaiTtsModel,
    String? openaiTtsVoice,
    double? openaiTtsSpeed,
    String? openaiTtsInstructions,
    String? openaiTtsFormat,
    bool? openaiSttReuseLlmKey,
    String? openaiSttBaseUrl,
    String? openaiSttModel,
    String? openaiSttPrompt,
    double? openaiSttTemperature,
    bool? googleSpeechReuseLlmKey,
    String? googleSpeechBaseUrl,
    String? googleTtsModel,
    String? googleTtsVoiceName,
    String? googleTtsStylePrompt,
    String? googleSttModel,
    int? timeoutSeconds,
  }) {
    return CloudSpeechConfig(
      id: id,
      elevenLabsBaseUrl: elevenLabsBaseUrl ?? this.elevenLabsBaseUrl,
      elevenLabsVoiceId: elevenLabsVoiceId ?? this.elevenLabsVoiceId,
      elevenLabsVoiceName: elevenLabsVoiceName ?? this.elevenLabsVoiceName,
      elevenLabsTtsModel: elevenLabsTtsModel ?? this.elevenLabsTtsModel,
      elevenLabsStability: elevenLabsStability ?? this.elevenLabsStability,
      elevenLabsSimilarityBoost:
          elevenLabsSimilarityBoost ?? this.elevenLabsSimilarityBoost,
      elevenLabsStyle: elevenLabsStyle ?? this.elevenLabsStyle,
      elevenLabsSpeed: elevenLabsSpeed ?? this.elevenLabsSpeed,
      elevenLabsUseSpeakerBoost:
          elevenLabsUseSpeakerBoost ?? this.elevenLabsUseSpeakerBoost,
      elevenLabsOutputFormat:
          elevenLabsOutputFormat ?? this.elevenLabsOutputFormat,
      elevenLabsSttModel: elevenLabsSttModel ?? this.elevenLabsSttModel,
      elevenLabsSttTagAudioEvents:
          elevenLabsSttTagAudioEvents ?? this.elevenLabsSttTagAudioEvents,
      elevenLabsSttDiarize: elevenLabsSttDiarize ?? this.elevenLabsSttDiarize,
      openaiTtsReuseLlmKey: openaiTtsReuseLlmKey ?? this.openaiTtsReuseLlmKey,
      openaiTtsBaseUrl: openaiTtsBaseUrl ?? this.openaiTtsBaseUrl,
      openaiTtsModel: openaiTtsModel ?? this.openaiTtsModel,
      openaiTtsVoice: openaiTtsVoice ?? this.openaiTtsVoice,
      openaiTtsSpeed: openaiTtsSpeed ?? this.openaiTtsSpeed,
      openaiTtsInstructions:
          openaiTtsInstructions ?? this.openaiTtsInstructions,
      openaiTtsFormat: openaiTtsFormat ?? this.openaiTtsFormat,
      openaiSttReuseLlmKey: openaiSttReuseLlmKey ?? this.openaiSttReuseLlmKey,
      openaiSttBaseUrl: openaiSttBaseUrl ?? this.openaiSttBaseUrl,
      openaiSttModel: openaiSttModel ?? this.openaiSttModel,
      openaiSttPrompt: openaiSttPrompt ?? this.openaiSttPrompt,
      openaiSttTemperature: openaiSttTemperature ?? this.openaiSttTemperature,
      googleSpeechReuseLlmKey:
          googleSpeechReuseLlmKey ?? this.googleSpeechReuseLlmKey,
      googleSpeechBaseUrl: googleSpeechBaseUrl ?? this.googleSpeechBaseUrl,
      googleTtsModel: googleTtsModel ?? this.googleTtsModel,
      googleTtsVoiceName: googleTtsVoiceName ?? this.googleTtsVoiceName,
      googleTtsStylePrompt: googleTtsStylePrompt ?? this.googleTtsStylePrompt,
      googleSttModel: googleSttModel ?? this.googleSttModel,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }

  /// Menormalkan seluruh field agar aman terhadap baris lama/korup.
  CloudSpeechConfig normalized() {
    return copyWith(
      elevenLabsBaseUrl: elevenLabsBaseUrl.trim(),
      elevenLabsVoiceId: elevenLabsVoiceId.trim().isEmpty
          ? 'EXAVITQu4vr4xnSDxMaL'
          : elevenLabsVoiceId.trim(),
      elevenLabsVoiceName: elevenLabsVoiceName.trim().isEmpty
          ? 'Sarah'
          : elevenLabsVoiceName.trim(),
      elevenLabsTtsModel: elevenLabsTtsModel.trim().isEmpty
          ? 'eleven_multilingual_v2'
          : elevenLabsTtsModel.trim(),
      elevenLabsStability: elevenLabsStability.clamp(0.0, 1.0).toDouble(),
      elevenLabsSimilarityBoost:
          elevenLabsSimilarityBoost.clamp(0.0, 1.0).toDouble(),
      elevenLabsStyle: elevenLabsStyle.clamp(0.0, 1.0).toDouble(),
      elevenLabsSpeed: elevenLabsSpeed.clamp(0.7, 1.2).toDouble(),
      elevenLabsOutputFormat:
          validElevenLabsFormats.contains(elevenLabsOutputFormat)
          ? elevenLabsOutputFormat
          : 'mp3_44100_128',
      elevenLabsSttModel: elevenLabsSttModel.trim().isEmpty
          ? 'scribe_v2'
          : elevenLabsSttModel.trim(),
      openaiTtsBaseUrl: openaiTtsBaseUrl.trim(),
      openaiTtsModel: openaiTtsModel.trim().isEmpty
          ? 'gpt-4o-mini-tts'
          : openaiTtsModel.trim(),
      openaiTtsVoice: openaiTtsVoice.trim().isEmpty
          ? 'coral'
          : openaiTtsVoice.trim(),
      openaiTtsSpeed: openaiTtsSpeed.clamp(0.25, 4.0).toDouble(),
      openaiTtsInstructions: openaiTtsInstructions.trim(),
      openaiTtsFormat: validOpenAiTtsFormats.contains(openaiTtsFormat)
          ? openaiTtsFormat
          : 'mp3',
      openaiSttBaseUrl: openaiSttBaseUrl.trim(),
      openaiSttModel: openaiSttModel.trim().isEmpty
          ? 'gpt-4o-mini-transcribe'
          : openaiSttModel.trim(),
      openaiSttPrompt: openaiSttPrompt.trim(),
      openaiSttTemperature: openaiSttTemperature.clamp(0.0, 1.0).toDouble(),
      googleSpeechBaseUrl: googleSpeechBaseUrl.trim(),
      googleTtsModel: googleTtsModel.trim().isEmpty
          ? 'gemini-2.5-flash-preview-tts'
          : googleTtsModel.trim(),
      googleTtsVoiceName: googleTtsVoiceName.trim().isEmpty
          ? 'Aoede'
          : googleTtsVoiceName.trim(),
      googleTtsStylePrompt: googleTtsStylePrompt.trim(),
      googleSttModel: googleSttModel.trim().isEmpty
          ? 'gemini-2.5-flash'
          : googleSttModel.trim(),
      timeoutSeconds: timeoutSeconds.clamp(10, 120),
    );
  }

  bool hasSameValues(CloudSpeechConfig other) {
    return elevenLabsBaseUrl == other.elevenLabsBaseUrl &&
        elevenLabsVoiceId == other.elevenLabsVoiceId &&
        elevenLabsVoiceName == other.elevenLabsVoiceName &&
        elevenLabsTtsModel == other.elevenLabsTtsModel &&
        elevenLabsStability == other.elevenLabsStability &&
        elevenLabsSimilarityBoost == other.elevenLabsSimilarityBoost &&
        elevenLabsStyle == other.elevenLabsStyle &&
        elevenLabsSpeed == other.elevenLabsSpeed &&
        elevenLabsUseSpeakerBoost == other.elevenLabsUseSpeakerBoost &&
        elevenLabsOutputFormat == other.elevenLabsOutputFormat &&
        elevenLabsSttModel == other.elevenLabsSttModel &&
        elevenLabsSttTagAudioEvents == other.elevenLabsSttTagAudioEvents &&
        elevenLabsSttDiarize == other.elevenLabsSttDiarize &&
        openaiTtsReuseLlmKey == other.openaiTtsReuseLlmKey &&
        openaiTtsBaseUrl == other.openaiTtsBaseUrl &&
        openaiTtsModel == other.openaiTtsModel &&
        openaiTtsVoice == other.openaiTtsVoice &&
        openaiTtsSpeed == other.openaiTtsSpeed &&
        openaiTtsInstructions == other.openaiTtsInstructions &&
        openaiTtsFormat == other.openaiTtsFormat &&
        openaiSttReuseLlmKey == other.openaiSttReuseLlmKey &&
        openaiSttBaseUrl == other.openaiSttBaseUrl &&
        openaiSttModel == other.openaiSttModel &&
        openaiSttPrompt == other.openaiSttPrompt &&
        openaiSttTemperature == other.openaiSttTemperature &&
        googleSpeechReuseLlmKey == other.googleSpeechReuseLlmKey &&
        googleSpeechBaseUrl == other.googleSpeechBaseUrl &&
        googleTtsModel == other.googleTtsModel &&
        googleTtsVoiceName == other.googleTtsVoiceName &&
        googleTtsStylePrompt == other.googleTtsStylePrompt &&
        googleSttModel == other.googleSttModel &&
        timeoutSeconds == other.timeoutSeconds;
  }
}
