// Facade orkestrasi Genkit untuk seluruh Cloud AI BYOK (LLM, TTS, STT, discovery).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genkit/genkit.dart' as gk;
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:genkit_openai/genkit_openai.dart';
import 'package:http/http.dart' as http;

import '../../../models/ai_provider_profile.dart';
import '../../../models/cloud_speech_config.dart';
import '../../../models/message.dart';
import '../../../models/persona_config.dart';
import '../prompt_builder.dart';
import 'compat_http_client.dart';
import 'elevenlabs_plugin.dart';
import 'provider_config_builder.dart';

/// Hasil sintesis audio Cloud TTS siap putar.
class SynthesizedAudio {
  final Uint8List bytes;
  final String mimeType;

  const SynthesizedAudio({required this.bytes, required this.mimeType});

  String get fileExtension {
    final lower = mimeType.toLowerCase();
    if (lower.contains('wav')) return 'wav';
    if (lower.contains('ogg') || lower.contains('opus')) return 'ogg';
    if (lower.contains('aac')) return 'aac';
    if (lower.contains('flac')) return 'flac';
    return 'mp3';
  }
}

/// Hasil uji koneksi provider Cloud BYOK.
class ConnectionTestResult {
  final bool ok;
  final int latencyMs;
  final String? sampleReply;
  final Object? error;

  const ConnectionTestResult({
    required this.ok,
    required this.latencyMs,
    this.sampleReply,
    this.error,
  });
}

/// Factory pembuat [http.Client] untuk injeksi mock pada pengujian.
typedef HttpClientFactory = http.Client Function();

/// Klien Cloud AI terpusat di atas ekosistem **Genkit Dart**.
///
/// Seluruh instance `Genkit` selalu dibuat dengan `isDevEnv: false` dan
/// `promptDir: null` agar aman dijalankan di perangkat mobile/desktop Flutter.
class GenkitCloudClient {
  const GenkitCloudClient({this.httpClientFactory});

  final HttpClientFactory? httpClientFactory;

  http.Client _createRawHttpClient() =>
      httpClientFactory != null ? httpClientFactory!() : http.Client();

  // ---------------------------------------------------------------------------
  // LLM Streaming & Unary Generation
  // ---------------------------------------------------------------------------

  /// Melakukan streaming balasan chat multi-turn dari profil Cloud BYOK.
  ///
  /// Hanya mengalirkan teks terlihat (`chunk.text`), menghormati
  /// [cancellation] (tombol Stop) dan `profile.timeoutSeconds`.
  Stream<String> streamChat({
    required AiProviderProfile profile,
    required String apiKey,
    required String systemPrompt,
    required List<CloudChatTurn> messages,
    gk.CancellationController? cancellation,
  }) async* {
    final cleanProfile = profile.normalized();
    _validateProfileAndKey(cleanProfile, apiKey);

    final cancelCtrl = cancellation ?? gk.CancellationController();
    var timedOut = false;
    final timeoutTimer = Timer(
      Duration(seconds: cleanProfile.timeoutSeconds),
      () {
        timedOut = true;
        cancelCtrl.cancel('Request timed out');
      },
    );

    final rawClient = _createRawHttpClient();
    final compatClient = CompatHttpClient(
      rawClient,
      stripStreamOptions:
          cleanProfile.providerType == LlmProviderType.openai &&
          cleanProfile.stripStreamOptions,
      extraHeaders: cleanProfile.parsedCustomHeaders(),
      cancelToken: cancelCtrl.token,
    );

    final ai = _createLlmGenkit(
      profile: cleanProfile,
      apiKey: apiKey.trim(),
      httpClient: compatClient,
    );

    final gkMessages = _toGenkitMessages(messages);
    try {
      final stream = _openLlmStream(
        ai: ai,
        profile: cleanProfile,
        systemPrompt: systemPrompt,
        messages: gkMessages,
        cancelToken: cancelCtrl.token,
      );

      await for (final chunk in stream) {
        if (cancelCtrl.isCancelled) break;
        final text = chunk.text;
        if (text.isNotEmpty) {
          yield text;
        }
      }

      if (timedOut) {
        throw TimeoutException(
          'Cloud generation timed out after ${cleanProfile.timeoutSeconds}s',
        );
      }

      if (!cancelCtrl.isCancelled) {
        final finalResult = await stream.onResult;
        _throwIfFailed(finalResult);
      }
    } on gk.CancelledException {
      if (timedOut) {
        throw TimeoutException(
          'Cloud generation timed out after ${cleanProfile.timeoutSeconds}s',
        );
      }
      // Pembatalan kooperatif oleh pengguna bukan kegagalan.
      return;
    } finally {
      timeoutTimer.cancel();
      compatClient.close();
      await ai.shutdown();
    }
  }

  /// Generasi teks non-streaming (untuk ekstraksi memori, ringkasan, dan tes koneksi).
  Future<String> generateText({
    required AiProviderProfile profile,
    required String apiKey,
    required String prompt,
    String? systemPrompt,
    String? modelOverride,
    int? maxOutputTokensOverride,
    double? temperatureOverride,
    bool disableThinking = true,
    gk.CancellationController? cancellation,
  }) async {
    final baseProfile = profile.normalized();
    final effectiveProfile =
        (modelOverride != null && modelOverride.trim().isNotEmpty)
        ? baseProfile.copyWith(modelId: modelOverride.trim())
        : baseProfile;
    _validateProfileAndKey(effectiveProfile, apiKey);

    final cancelCtrl = cancellation ?? gk.CancellationController();
    var timedOut = false;
    final timeoutTimer = Timer(
      Duration(seconds: effectiveProfile.timeoutSeconds),
      () {
        timedOut = true;
        cancelCtrl.cancel('Request timed out');
      },
    );

    final rawClient = _createRawHttpClient();
    final compatClient = CompatHttpClient(
      rawClient,
      stripStreamOptions:
          effectiveProfile.providerType == LlmProviderType.openai &&
          effectiveProfile.stripStreamOptions,
      extraHeaders: effectiveProfile.parsedCustomHeaders(),
      cancelToken: cancelCtrl.token,
    );

    final ai = _createLlmGenkit(
      profile: effectiveProfile,
      apiKey: apiKey.trim(),
      httpClient: compatClient,
    );

    try {
      final result = await _runLlmUnary(
        ai: ai,
        profile: effectiveProfile,
        prompt: prompt,
        systemPrompt: systemPrompt,
        maxOutputTokensOverride: maxOutputTokensOverride,
        temperatureOverride: temperatureOverride,
        disableThinking: disableThinking,
        cancelToken: cancelCtrl.token,
      );
      if (timedOut) {
        throw TimeoutException(
          'Cloud request timed out after ${effectiveProfile.timeoutSeconds}s',
        );
      }
      _throwIfFailed(result);
      return result.text.trim();
    } on gk.CancelledException {
      if (timedOut) {
        throw TimeoutException(
          'Cloud request timed out after ${effectiveProfile.timeoutSeconds}s',
        );
      }
      return '';
    } finally {
      timeoutTimer.cancel();
      compatClient.close();
      await ai.shutdown();
    }
  }

  /// Menguji koneksi, kredensial, dan model pada [profile] dengan permintaan ringan.
  Future<ConnectionTestResult> testConnection({
    required AiProviderProfile profile,
    required String apiKey,
  }) async {
    final watch = Stopwatch()..start();
    try {
      final reply = await generateText(
        profile: profile.copyWith(
          timeoutSeconds: profile.timeoutSeconds.clamp(15, 30),
        ),
        apiKey: apiKey,
        prompt: 'Reply with OK.',
        maxOutputTokensOverride: 16,
        temperatureOverride: 0.0,
        disableThinking: true,
      );
      watch.stop();
      return ConnectionTestResult(
        ok: true,
        latencyMs: watch.elapsedMilliseconds,
        sampleReply: reply,
      );
    } catch (e) {
      watch.stop();
      return ConnectionTestResult(
        ok: false,
        latencyMs: watch.elapsedMilliseconds,
        error: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Dynamic Model Discovery
  // ---------------------------------------------------------------------------

  /// Mengambil daftar model yang tersedia dari endpoint `/models` provider.
  Future<List<String>> fetchAvailableModels({
    required LlmProviderType providerType,
    required String apiKey,
    String? baseUrl,
    Map<String, String> headers = const {},
  }) async {
    final cleanKey = apiKey.trim();
    final cleanBase = normalizeBaseUrl(baseUrl ?? '');
    if (cleanBase != null && !isValidBaseUrl(cleanBase)) {
      throw gk.GenkitException(
        'Invalid base URL.',
        status: gk.StatusCode.invalidArgument,
      );
    }
    if (cleanKey.isEmpty &&
        !(providerType == LlmProviderType.openai &&
            AiProviderProfile.isLocalNetworkUrl(cleanBase ?? ''))) {
      throw gk.GenkitException(
        'API key is required.',
        status: gk.StatusCode.unauthenticated,
      );
    }

    final client = _createRawHttpClient();
    try {
      final Uri uri;
      final reqHeaders = <String, String>{
        'Accept': 'application/json',
        ...headers,
      };

      switch (providerType) {
        case LlmProviderType.google:
          final root =
              normalizeGoogleBaseUrl(baseUrl ?? '') ??
              'https://generativelanguage.googleapis.com';
          uri = Uri.parse('$root/v1beta/models');
          reqHeaders['x-goog-api-key'] = cleanKey;
        case LlmProviderType.anthropic:
          final root =
              normalizeAnthropicBaseUrl(baseUrl ?? '') ??
              'https://api.anthropic.com';
          uri = Uri.parse('$root/v1/models');
          reqHeaders['x-api-key'] = cleanKey;
          reqHeaders.putIfAbsent('anthropic-version', () => '2023-06-01');
        case LlmProviderType.openai:
          final root = cleanBase ?? 'https://api.openai.com/v1';
          uri = Uri.parse('$root/models');
          if (cleanKey.isNotEmpty) {
            reqHeaders['Authorization'] = 'Bearer $cleanKey';
          }
      }

      final response = await client
          .get(uri, headers: reqHeaders)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw gk.GenkitException(
          'Model listing failed (HTTP ${response.statusCode})',
          status: gk.StatusCode.fromHttpStatus(response.statusCode),
        );
      }

      final decoded = jsonDecode(response.body);
      final ids = <String>{};
      if (providerType == LlmProviderType.google) {
        final list = decoded is Map ? decoded['models'] : null;
        if (list is List) {
          for (final item in list) {
            if (item is! Map) continue;
            final name = '${item['name'] ?? ''}'.trim();
            if (name.isEmpty) continue;
            final cleanName = name.startsWith('models/')
                ? name.substring('models/'.length)
                : name;
            final methods = item['supportedGenerationMethods'];
            if (methods is List &&
                methods.isNotEmpty &&
                !methods.contains('generateContent')) {
              continue;
            }
            ids.add(cleanName);
          }
        }
      } else {
        final list = decoded is Map ? decoded['data'] : null;
        if (list is List) {
          for (final item in list) {
            if (item is! Map) continue;
            final id = '${item['id'] ?? ''}'.trim();
            if (id.isNotEmpty) ids.add(id);
          }
        }
      }

      final sorted = ids.toList()..sort();
      return sorted;
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Cloud Speech: TTS & STT via Genkit
  // ---------------------------------------------------------------------------

  /// Menyintesis [text] menjadi audio melalui provider Cloud TTS via Genkit.
  ///
  /// [backend] yang didukung: `'elevenlabs'`, `'openai'`, `'google'`.
  Future<SynthesizedAudio> synthesizeSpeech({
    required String backend,
    required CloudSpeechConfig config,
    required String apiKey,
    required String text,
    String? languageCode,
    PersonaGender? gender,
    gk.CancellationController? cancellation,
  }) async {
    final c = config.normalized();
    final cleanKey = apiKey.trim();
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      throw gk.GenkitException(
        'TTS text is empty.',
        status: gk.StatusCode.invalidArgument,
      );
    }

    final cancelCtrl = cancellation ?? gk.CancellationController();
    var timedOut = false;
    final timer = Timer(Duration(seconds: c.timeoutSeconds), () {
      timedOut = true;
      cancelCtrl.cancel('Cloud TTS timed out');
    });

    final rawClient = _createRawHttpClient();
    final compatClient = CompatHttpClient(
      rawClient,
      cancelToken: cancelCtrl.token,
    );

    gk.Genkit? ai;
    try {
      final gk.GenerateResult<dynamic> result;
      switch (backend) {
        case 'elevenlabs':
          if (cleanKey.isEmpty) {
            throw gk.GenkitException(
              'ElevenLabs API key is required.',
              status: gk.StatusCode.unauthenticated,
            );
          }
          ai = gk.Genkit(
            plugins: [
              elevenLabs(
                apiKey: cleanKey,
                baseUrl: normalizeBaseUrl(c.elevenLabsBaseUrl),
                httpClient: compatClient,
              ),
            ],
            isDevEnv: false,
            promptDir: null,
          );
          result = await ai.generate(
            model: elevenLabs.ttsModel(c.elevenLabsTtsModel),
            prompt: cleanText,
            config: {
              'voiceId': c.elevenLabsVoiceId,
              'outputFormat': c.elevenLabsOutputFormat,
              'stability': c.elevenLabsStability,
              'similarityBoost': c.elevenLabsSimilarityBoost,
              'style': c.elevenLabsStyle,
              'speed': c.elevenLabsSpeed,
              'useSpeakerBoost': c.elevenLabsUseSpeakerBoost,
              'languageCode': languageCode,
            },
            cancel: cancelCtrl.token,
          );

        case 'openai':
          final baseUrl = normalizeBaseUrl(c.openaiTtsBaseUrl);
          if (cleanKey.isEmpty &&
              !AiProviderProfile.isLocalNetworkUrl(baseUrl ?? '')) {
            throw gk.GenkitException(
              'OpenAI TTS API key is required.',
              status: gk.StatusCode.unauthenticated,
            );
          }
          const ns = 'openai_tts';
          ai = gk.Genkit(
            plugins: [
              openAI(
                name: ns,
                apiKey: cleanKey.isEmpty ? 'local' : cleanKey,
                baseUrl: baseUrl,
                httpClient: compatClient,
                models: [
                  CustomModelDefinition(
                    name: c.openaiTtsModel,
                    kind: OpenAIModelKind.speech,
                  ),
                ],
              ),
            ],
            isDevEnv: false,
            promptDir: null,
          );
          result = await ai.generate(
            model: openAI.speechModel(c.openaiTtsModel, namespace: ns),
            prompt: cleanText,
            config: buildOpenAiSpeechOptions(c),
            cancel: cancelCtrl.token,
          );

        case 'google':
          if (cleanKey.isEmpty) {
            throw gk.GenkitException(
              'Google API key is required.',
              status: gk.StatusCode.unauthenticated,
            );
          }
          ai = gk.Genkit(
            plugins: [
              googleAI(
                apiKey: cleanKey,
                baseUrl: normalizeGoogleBaseUrl(c.googleSpeechBaseUrl),
              ),
            ],
            isDevEnv: false,
            promptDir: null,
          );
          final styledPrompt = c.googleTtsStylePrompt.isNotEmpty
              ? '${c.googleTtsStylePrompt}: $cleanText'
              : cleanText;
          result = await ai.generate(
            model: googleAI.geminiTts(c.googleTtsModel),
            prompt: styledPrompt,
            config: buildGeminiTtsOptions(c),
            cancel: cancelCtrl.token,
          );

        default:
          throw gk.GenkitException(
            'Unsupported cloud TTS backend: $backend',
            status: gk.StatusCode.invalidArgument,
          );
      }

      if (timedOut) {
        throw TimeoutException('Cloud TTS timed out after ${c.timeoutSeconds}s');
      }
      _throwIfFailed(result);
      return _extractSynthesizedAudio(result, fallbackFormat: c.elevenLabsOutputFormat);
    } on gk.CancelledException {
      if (timedOut) {
        throw TimeoutException('Cloud TTS timed out after ${c.timeoutSeconds}s');
      }
      rethrow;
    } finally {
      timer.cancel();
      compatClient.close();
      await ai?.shutdown();
    }
  }

  /// Mentranskrip audio WAV menjadi teks melalui provider Cloud STT via Genkit.
  ///
  /// [backend] yang didukung: `'elevenlabs'`, `'openai'`, `'google'`.
  Future<String> transcribeAudio({
    required String backend,
    required CloudSpeechConfig config,
    required String apiKey,
    required Uint8List wavBytes,
    String? languageCode,
    gk.CancellationController? cancellation,
  }) async {
    final c = config.normalized();
    final cleanKey = apiKey.trim();
    if (wavBytes.isEmpty) return '';

    final cancelCtrl = cancellation ?? gk.CancellationController();
    var timedOut = false;
    final timer = Timer(Duration(seconds: c.timeoutSeconds), () {
      timedOut = true;
      cancelCtrl.cancel('Cloud STT timed out');
    });

    final rawClient = _createRawHttpClient();
    final compatClient = CompatHttpClient(
      rawClient,
      cancelToken: cancelCtrl.token,
    );

    final media = gk.Media(
      url: 'data:audio/wav;base64,${base64Encode(wavBytes)}',
      contentType: 'audio/wav',
    );

    gk.Genkit? ai;
    try {
      final gk.GenerateResult<dynamic> result;
      switch (backend) {
        case 'elevenlabs':
          if (cleanKey.isEmpty) {
            throw gk.GenkitException(
              'ElevenLabs API key is required.',
              status: gk.StatusCode.unauthenticated,
            );
          }
          ai = gk.Genkit(
            plugins: [
              elevenLabs(
                apiKey: cleanKey,
                baseUrl: normalizeBaseUrl(c.elevenLabsBaseUrl),
                httpClient: compatClient,
              ),
            ],
            isDevEnv: false,
            promptDir: null,
          );
          result = await ai.generate(
            model: elevenLabs.sttModel(c.elevenLabsSttModel),
            promptParts: [gk.MediaPart(media: media)],
            config: {
              'languageCode': languageCode,
              'tagAudioEvents': c.elevenLabsSttTagAudioEvents,
              'diarize': c.elevenLabsSttDiarize,
            },
            cancel: cancelCtrl.token,
          );

        case 'openai':
          final baseUrl = normalizeBaseUrl(c.openaiSttBaseUrl);
          if (cleanKey.isEmpty &&
              !AiProviderProfile.isLocalNetworkUrl(baseUrl ?? '')) {
            throw gk.GenkitException(
              'OpenAI STT API key is required.',
              status: gk.StatusCode.unauthenticated,
            );
          }
          const ns = 'openai_stt';
          ai = gk.Genkit(
            plugins: [
              openAI(
                name: ns,
                apiKey: cleanKey.isEmpty ? 'local' : cleanKey,
                baseUrl: baseUrl,
                httpClient: compatClient,
                models: [
                  CustomModelDefinition(
                    name: c.openaiSttModel,
                    kind: OpenAIModelKind.transcription,
                  ),
                ],
              ),
            ],
            isDevEnv: false,
            promptDir: null,
          );
          result = await ai.generate(
            model: openAI.transcriptionModel(c.openaiSttModel, namespace: ns),
            promptParts: [gk.MediaPart(media: media)],
            config: buildOpenAiTranscriptionOptions(
              c,
              languageCode: languageCode,
            ),
            cancel: cancelCtrl.token,
          );

        case 'google':
          if (cleanKey.isEmpty) {
            throw gk.GenkitException(
              'Google API key is required.',
              status: gk.StatusCode.unauthenticated,
            );
          }
          ai = gk.Genkit(
            plugins: [
              googleAI(
                apiKey: cleanKey,
                baseUrl: normalizeGoogleBaseUrl(c.googleSpeechBaseUrl),
              ),
            ],
            isDevEnv: false,
            promptDir: null,
          );
          final langHint = iso6391Language(languageCode);
          final instruction = langHint != null
              ? 'Transcribe the spoken audio accurately verbatim (primary language hint: $langHint). Output ONLY the transcription text, nothing else.'
              : 'Transcribe the spoken audio accurately verbatim. Output ONLY the transcription text, nothing else.';
          result = await ai.generate(
            model: googleAI.gemini(c.googleSttModel),
            promptParts: [
              gk.TextPart(text: instruction),
              gk.MediaPart(media: media),
            ],
            config: GeminiOptions(temperature: 0.0, maxOutputTokens: 1024),
            cancel: cancelCtrl.token,
          );

        default:
          throw gk.GenkitException(
            'Unsupported cloud STT backend: $backend',
            status: gk.StatusCode.invalidArgument,
          );
      }

      if (timedOut) {
        throw TimeoutException('Cloud STT timed out after ${c.timeoutSeconds}s');
      }
      _throwIfFailed(result);
      return result.text.trim();
    } on gk.CancelledException {
      if (timedOut) {
        throw TimeoutException('Cloud STT timed out after ${c.timeoutSeconds}s');
      }
      return '';
    } finally {
      timer.cancel();
      compatClient.close();
      await ai?.shutdown();
    }
  }

  /// Mengambil daftar suara akun ElevenLabs pengguna.
  Future<List<ElevenLabsVoice>> fetchElevenLabsVoices({
    required String apiKey,
    String? baseUrl,
  }) async {
    final client = _createRawHttpClient();
    try {
      return await ElevenLabsVoicesApi.fetchVoices(
        apiKey: apiKey,
        baseUrl: baseUrl,
        httpClient: client,
      );
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _validateProfileAndKey(AiProviderProfile profile, String apiKey) {
    if (profile.modelId.trim().isEmpty) {
      throw gk.GenkitException(
        'Model ID is empty.',
        status: gk.StatusCode.invalidArgument,
      );
    }
    if (!isValidBaseUrl(profile.baseUrl)) {
      throw gk.GenkitException(
        'Base URL is invalid.',
        status: gk.StatusCode.invalidArgument,
      );
    }
    final cleanKey = apiKey.trim();
    final allowBlank =
        profile.providerType == LlmProviderType.openai &&
        profile.isLocalNetworkBaseUrl;
    if (cleanKey.isEmpty && !allowBlank) {
      throw gk.GenkitException(
        'API key is missing.',
        status: gk.StatusCode.unauthenticated,
      );
    }
  }

  gk.Genkit _createLlmGenkit({
    required AiProviderProfile profile,
    required String apiKey,
    required http.Client httpClient,
  }) {
    final headers = profile.parsedCustomHeaders();
    final effectiveHeaders = headers.isNotEmpty ? headers : null;

    final gk.GenkitPlugin plugin = switch (profile.providerType) {
      LlmProviderType.google => googleAI(
        apiKey: apiKey,
        baseUrl: normalizeGoogleBaseUrl(profile.baseUrl),
      ),
      LlmProviderType.anthropic => anthropic(
        apiKey: apiKey,
        baseUrl: normalizeAnthropicBaseUrl(profile.baseUrl),
        headers: effectiveHeaders,
        httpClient: httpClient,
      ),
      LlmProviderType.openai => openAI(
        name: _openAiNamespace(profile),
        apiKey: apiKey.isEmpty ? 'local' : apiKey,
        baseUrl: normalizeBaseUrl(profile.baseUrl),
        headers: effectiveHeaders,
        httpClient: httpClient,
        models: [
          CustomModelDefinition(
            name: profile.modelId,
            kind: OpenAIModelKind.chat,
          ),
        ],
      ),
    };

    return gk.Genkit(
      plugins: [plugin],
      isDevEnv: false,
      promptDir: null,
    );
  }

  /// Melempar [gk.GenkitException] bila [GenerateResult] membawa status gagal.
  ///
  /// Di Genkit 1.0.x, kegagalan model (HTTP 401/403/404/429/5xx, jaringan, dll.)
  /// dikembalikan melalui `result.finishReason == FinishReason.failed` +
  /// `result.error` dan tidak selalu otomatis dilempar oleh `ai.generate`.
  static void _throwIfFailed(gk.GenerateResult<dynamic> result) {
    final err = result.error;
    if (err == null && result.finishReason != gk.FinishReason.failed) return;

    final cause = result.cause;
    if (cause is gk.CancelledException) throw cause;
    if (cause is gk.GenkitException) throw cause;
    if (cause is TimeoutException) throw cause;

    final statusWire = err?.status;
    final status = (statusWire != null && statusWire.isNotEmpty)
        ? gk.StatusCode.fromWireName(statusWire)
        : gk.StatusCode.unknown;
    final message =
        err?.message ?? result.finishMessage ?? 'Cloud AI request failed';
    throw gk.GenkitException(message, status: status, cause: cause);
  }

  gk.ActionStream<gk.GenerateResponseChunk<dynamic>, gk.GenerateResult<dynamic>>
  _openLlmStream({
    required gk.Genkit ai,
    required AiProviderProfile profile,
    required String systemPrompt,
    required List<gk.Message> messages,
    required gk.CancellationToken cancelToken,
  }) {
    switch (profile.providerType) {
      case LlmProviderType.google:
        return ai.generateStream(
          model: googleAI.gemini(profile.modelId),
          system: systemPrompt,
          messages: messages,
          config: buildGeminiOptions(profile),
          cancel: cancelToken,
        );
      case LlmProviderType.anthropic:
        return ai.generateStream(
          model: anthropic.model(profile.modelId),
          system: systemPrompt,
          messages: messages,
          config: buildAnthropicOptions(profile),
          cancel: cancelToken,
        );
      case LlmProviderType.openai:
        return ai.generateStream(
          model: openAI.model(
            profile.modelId,
            namespace: _openAiNamespace(profile),
          ),
          system: systemPrompt,
          messages: messages,
          config: buildOpenAIOptions(profile),
          cancel: cancelToken,
        );
    }
  }

  Future<gk.GenerateResult<dynamic>> _runLlmUnary({
    required gk.Genkit ai,
    required AiProviderProfile profile,
    required String prompt,
    String? systemPrompt,
    int? maxOutputTokensOverride,
    double? temperatureOverride,
    required bool disableThinking,
    required gk.CancellationToken cancelToken,
  }) {
    switch (profile.providerType) {
      case LlmProviderType.google:
        return ai.generate(
          model: googleAI.gemini(profile.modelId),
          system: systemPrompt,
          prompt: prompt,
          config: buildGeminiOptions(
            profile,
            maxOutputTokensOverride: maxOutputTokensOverride,
            temperatureOverride: temperatureOverride,
            disableThinking: disableThinking,
          ),
          cancel: cancelToken,
        );
      case LlmProviderType.anthropic:
        return ai.generate(
          model: anthropic.model(profile.modelId),
          system: systemPrompt,
          prompt: prompt,
          config: buildAnthropicOptions(
            profile,
            maxOutputTokensOverride: maxOutputTokensOverride,
            temperatureOverride: temperatureOverride,
            disableThinking: disableThinking,
          ),
          cancel: cancelToken,
        );
      case LlmProviderType.openai:
        return ai.generate(
          model: openAI.model(
            profile.modelId,
            namespace: _openAiNamespace(profile),
          ),
          system: systemPrompt,
          prompt: prompt,
          config: buildOpenAIOptions(
            profile,
            maxOutputTokensOverride: maxOutputTokensOverride,
            temperatureOverride: temperatureOverride,
            disableReasoning: disableThinking,
          ),
          cancel: cancelToken,
        );
    }
  }

  static String _openAiNamespace(AiProviderProfile profile) {
    final base = normalizeBaseUrl(profile.baseUrl);
    return base == null ? defaultOpenAINamespace : 'openai_compat';
  }

  static List<gk.Message> _toGenkitMessages(List<CloudChatTurn> turns) {
    return [
      for (final turn in turns)
        gk.Message(
          role: turn.role == MessageRole.user ? gk.Role.user : gk.Role.model,
          content: [gk.TextPart(text: turn.content)],
        ),
    ];
  }

  static SynthesizedAudio _extractSynthesizedAudio(
    gk.GenerateResult<dynamic> result, {
    required String fallbackFormat,
  }) {
    final media = result.media;
    if (media == null) {
      throw gk.GenkitException(
        'Cloud TTS returned no audio media.',
        status: gk.StatusCode.internal,
      );
    }
    final rawBytes = decodeDataUriBytes(media.url);
    if (rawBytes == null || rawBytes.isEmpty) {
      throw gk.GenkitException(
        'Cloud TTS returned invalid audio data.',
        status: gk.StatusCode.internal,
      );
    }

    final rawMime = (media.contentType ?? '').trim();
    final lower = rawMime.toLowerCase();
    // Bungkus raw PCM / audio/l16 menjadi WAV RIFF agar bisa diputar langsung
    // oleh audioplayers dengan callback selesai akurat.
    if (lower.startsWith('audio/pcm') || lower.startsWith('audio/l16')) {
      final rate =
          sampleRateFromMimeOrFormat(rawMime) ??
          sampleRateFromMimeOrFormat(fallbackFormat) ??
          24000;
      return SynthesizedAudio(
        bytes: wrapPcmAsWav(rawBytes, sampleRate: rate),
        mimeType: 'audio/wav',
      );
    }

    return SynthesizedAudio(
      bytes: rawBytes,
      mimeType: rawMime.isNotEmpty ? rawMime : 'audio/mpeg',
    );
  }
}

final genkitCloudClientProvider = Provider<GenkitCloudClient>(
  (ref) => const GenkitCloudClient(),
);
