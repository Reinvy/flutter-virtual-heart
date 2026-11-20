// Custom GenkitPlugin untuk ElevenLabs Cloud TTS & STT Scribe + API daftar suara.
import 'dart:convert';
import 'dart:typed_data';

import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

import 'provider_config_builder.dart';

/// Base URL default API ElevenLabs v1.
const String kDefaultElevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';

/// Handle publik untuk mendaftarkan plugin & merujuk model TTS/STT ElevenLabs
/// lewat Genkit.
const ElevenLabsPluginHandle elevenLabs = ElevenLabsPluginHandle();

/// Metadata satu suara ElevenLabs hasil `GET /v1/voices`.
class ElevenLabsVoice {
  final String voiceId;
  final String name;
  final String category;
  final String description;

  const ElevenLabsVoice({
    required this.voiceId,
    required this.name,
    this.category = '',
    this.description = '',
  });
}

/// Handle plugin Genkit untuk ElevenLabs.
class ElevenLabsPluginHandle {
  const ElevenLabsPluginHandle();

  /// Membuat instance [ElevenLabsGenkitPlugin].
  GenkitPlugin call({
    required String apiKey,
    String? baseUrl,
    http.Client? httpClient,
  }) {
    return ElevenLabsGenkitPlugin(
      apiKey: apiKey,
      baseUrl: baseUrl,
      httpClient: httpClient,
    );
  }

  /// Referensi model TTS ElevenLabs (mis. `eleven_multilingual_v2`).
  ModelRef<Map<String, dynamic>> ttsModel(String modelId) {
    return modelRef<Map<String, dynamic>>('elevenlabs/tts/$modelId');
  }

  /// Referensi model STT Scribe ElevenLabs (mis. `scribe_v2`).
  ModelRef<Map<String, dynamic>> sttModel(String modelId) {
    return modelRef<Map<String, dynamic>>('elevenlabs/stt/$modelId');
  }
}

/// Plugin Genkit kustom yang mengekspos ElevenLabs Text-to-Speech dan
/// Speech-to-Text (Scribe) sebagai `Model` Genkit standar.
class ElevenLabsGenkitPlugin extends GenkitPlugin {
  ElevenLabsGenkitPlugin({
    required this.apiKey,
    String? baseUrl,
    this.httpClient,
  }) : baseUrl = normalizeBaseUrl(baseUrl ?? '') ?? kDefaultElevenLabsBaseUrl;

  final String apiKey;
  final String baseUrl;
  final http.Client? httpClient;

  @override
  String get name => 'elevenlabs';

  @override
  Action? resolve(ActionType actionType, String name) {
    if (actionType != ActionType.model) return null;
    if (name.startsWith('tts/')) {
      final modelId = name.substring('tts/'.length);
      return _buildTtsModel(modelId);
    }
    if (name.startsWith('stt/')) {
      final modelId = name.substring('stt/'.length);
      return _buildSttModel(modelId);
    }
    return null;
  }

  Model<Map<String, dynamic>> _buildTtsModel(String modelId) {
    return Model<Map<String, dynamic>>(
      name: '$name/tts/$modelId',
      metadata: {
        'model': ModelInfo(
          label: 'ElevenLabs TTS ($modelId)',
          supports: const {
            'multiturn': false,
            'media': false,
            'tools': false,
            'systemRole': false,
            'output': ['media'],
          },
        ).toJson(),
      },
      fn: (req, ctx) async {
        ctx.cancel?.throwIfCancelled();
        if (apiKey.trim().isEmpty) {
          throw GenkitException(
            'ElevenLabs API key is required.',
            status: StatusCode.unauthenticated,
          );
        }

        final text = _extractInputText(req.messages);
        if (text.isEmpty) {
          throw GenkitException(
            'TTS input text is empty.',
            status: StatusCode.invalidArgument,
          );
        }

        final cfg = req.config ?? const <String, dynamic>{};
        final voiceId = ((cfg['voiceId'] as String?) ?? '').trim();
        if (voiceId.isEmpty) {
          throw GenkitException(
            'ElevenLabs voiceId is required.',
            status: StatusCode.invalidArgument,
          );
        }

        final outputFormat =
            ((cfg['outputFormat'] as String?) ?? 'mp3_44100_128').trim();
        final stability = (cfg['stability'] as num?)?.toDouble();
        final similarityBoost = (cfg['similarityBoost'] as num?)?.toDouble();
        final style = (cfg['style'] as num?)?.toDouble();
        final speed = (cfg['speed'] as num?)?.toDouble();
        final useSpeakerBoost = cfg['useSpeakerBoost'] as bool?;
        final languageCode = iso6391Language(cfg['languageCode'] as String?);

        final voiceSettings = <String, dynamic>{
          if (stability != null) 'stability': stability.clamp(0.0, 1.0),
          if (similarityBoost != null)
            'similarity_boost': similarityBoost.clamp(0.0, 1.0),
          // Hanya kirim `style` bila > 0 agar kompatibel dengan model yang
          // tidak menerima style non-default.
          if (style != null && style > 0) 'style': style.clamp(0.0, 1.0),
          if (speed != null) 'speed': speed.clamp(0.7, 1.2),
          'use_speaker_boost': ?useSpeakerBoost,
        };

        final payload = <String, dynamic>{
          'text': text,
          'model_id': modelId,
          if (voiceSettings.isNotEmpty) 'voice_settings': voiceSettings,
          if (languageCode != null && modelId.contains('v2_5'))
            'language_code': languageCode,
        };

        final uri = Uri.parse(
          '$baseUrl/text-to-speech/${Uri.encodeComponent(voiceId)}',
        ).replace(queryParameters: {'output_format': outputFormat});

        final mime = mimeTypeForElevenLabsFormat(outputFormat);
        final ownClient = httpClient == null;
        final client = httpClient ?? http.Client();
        try {
          ctx.cancel?.throwIfCancelled();
          final response = await client.post(
            uri,
            headers: {
              'xi-api-key': apiKey.trim(),
              'Content-Type': 'application/json',
              'Accept': mime,
            },
            body: jsonEncode(payload),
          );
          ctx.cancel?.throwIfCancelled();

          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw _mapHttpError('ElevenLabs TTS', response.statusCode, response.body);
          }

          if (response.bodyBytes.isEmpty) {
            throw GenkitException(
              'ElevenLabs TTS returned empty audio.',
              status: StatusCode.internal,
            );
          }

          final actualMime =
              response.headers['content-type']?.split(';').first.trim();
          final resolvedMime = (actualMime != null && actualMime.startsWith('audio/'))
              ? actualMime
              : mime;
          final dataUrl =
              'data:$resolvedMime;base64,${base64Encode(response.bodyBytes)}';

          return ModelResponse(
            finishReason: FinishReason.stop,
            message: Message(
              role: Role.model,
              content: [
                MediaPart(
                  media: Media(url: dataUrl, contentType: resolvedMime),
                ),
              ],
            ),
          );
        } finally {
          if (ownClient) client.close();
        }
      },
    );
  }

  Model<Map<String, dynamic>> _buildSttModel(String modelId) {
    return Model<Map<String, dynamic>>(
      name: '$name/stt/$modelId',
      metadata: {
        'model': ModelInfo(
          label: 'ElevenLabs STT ($modelId)',
          supports: const {
            'multiturn': false,
            'media': true,
            'tools': false,
            'systemRole': false,
            'output': ['text'],
          },
        ).toJson(),
      },
      fn: (req, ctx) async {
        ctx.cancel?.throwIfCancelled();
        if (apiKey.trim().isEmpty) {
          throw GenkitException(
            'ElevenLabs API key is required.',
            status: StatusCode.unauthenticated,
          );
        }

        final media = _extractInputMedia(req.messages);
        if (media == null) {
          throw GenkitException(
            'STT request requires an audio MediaPart.',
            status: StatusCode.invalidArgument,
          );
        }

        final audioBytes = decodeDataUriBytes(media.url);
        if (audioBytes == null || audioBytes.isEmpty) {
          throw GenkitException(
            'Invalid or empty audio payload for ElevenLabs STT.',
            status: StatusCode.invalidArgument,
          );
        }

        final cfg = req.config ?? const <String, dynamic>{};
        final languageCode = iso6391Language(cfg['languageCode'] as String?);
        final tagAudioEvents = cfg['tagAudioEvents'] == true;
        final diarize = cfg['diarize'] == true;

        final uri = Uri.parse('$baseUrl/speech-to-text');
        final request = http.MultipartRequest('POST', uri)
          ..headers['xi-api-key'] = apiKey.trim()
          ..fields['model_id'] = modelId
          ..fields['tag_audio_events'] = tagAudioEvents.toString()
          ..fields['diarize'] = diarize.toString();

        if (languageCode != null && languageCode.isNotEmpty) {
          request.fields['language_code'] = languageCode;
        }

        final mime = media.contentType ?? 'audio/wav';
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            audioBytes,
            filename: mime.contains('wav') ? 'recording.wav' : 'recording.mp3',
          ),
        );

        final ownClient = httpClient == null;
        final client = httpClient ?? http.Client();
        try {
          ctx.cancel?.throwIfCancelled();
          final streamed = await client.send(request);
          final response = await http.Response.fromStream(streamed);
          ctx.cancel?.throwIfCancelled();

          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw _mapHttpError('ElevenLabs STT', response.statusCode, response.body);
          }

          final decoded = jsonDecode(response.body);
          final text = decoded is Map ? ('${decoded['text'] ?? ''}').trim() : '';

          return ModelResponse(
            finishReason: FinishReason.stop,
            message: Message(
              role: Role.model,
              content: [TextPart(text: text)],
            ),
          );
        } finally {
          if (ownClient) client.close();
        }
      },
    );
  }
}

/// Helper API untuk mengambil daftar suara akun ElevenLabs (`GET /v1/voices`).
abstract final class ElevenLabsVoicesApi {
  static Future<List<ElevenLabsVoice>> fetchVoices({
    required String apiKey,
    String? baseUrl,
    http.Client? httpClient,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw GenkitException(
        'ElevenLabs API key is required.',
        status: StatusCode.unauthenticated,
      );
    }
    final root = normalizeBaseUrl(baseUrl ?? '') ?? kDefaultElevenLabsBaseUrl;
    final uri = Uri.parse('$root/voices');
    final ownClient = httpClient == null;
    final client = httpClient ?? http.Client();
    try {
      final response = await client.get(
        uri,
        headers: {'xi-api-key': cleanKey, 'Accept': 'application/json'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError('ElevenLabs Voices', response.statusCode, response.body);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['voices'] is! List) return const [];
      final voices = <ElevenLabsVoice>[];
      for (final item in decoded['voices'] as List) {
        if (item is! Map) continue;
        final id = '${item['voice_id'] ?? ''}'.trim();
        final name = '${item['name'] ?? ''}'.trim();
        if (id.isEmpty || name.isEmpty) continue;
        final category = '${item['category'] ?? ''}'.trim();
        final labels = item['labels'];
        String desc = '';
        if (labels is Map && labels.isNotEmpty) {
          desc = labels.values
              .map((v) => '$v'.trim())
              .where((v) => v.isNotEmpty)
              .take(3)
              .join(' · ');
        }
        voices.add(
          ElevenLabsVoice(
            voiceId: id,
            name: name,
            category: category,
            description: desc,
          ),
        );
      }
      return voices;
    } finally {
      if (ownClient) client.close();
    }
  }
}

/// Memetakan format output ElevenLabs menjadi MIME type.
String mimeTypeForElevenLabsFormat(String outputFormat) {
  final lower = outputFormat.toLowerCase();
  if (lower.startsWith('pcm_')) {
    final rate = int.tryParse(lower.substring('pcm_'.length));
    return rate != null ? 'audio/pcm;rate=$rate' : 'audio/pcm';
  }
  if (lower.startsWith('ulaw_')) return 'audio/basic';
  return 'audio/mpeg';
}

/// Mengekstrak sample rate (Hz) dari format PCM ElevenLabs atau parameter MIME `rate=...`.
int? sampleRateFromMimeOrFormat(String mimeOrFormat) {
  final rateMatch = RegExp(r'rate=(\d+)').firstMatch(mimeOrFormat);
  if (rateMatch != null) return int.tryParse(rateMatch.group(1)!);
  final pcmMatch = RegExp(r'pcm_(\d+)').firstMatch(mimeOrFormat.toLowerCase());
  if (pcmMatch != null) return int.tryParse(pcmMatch.group(1)!);
  return null;
}

/// Mendekode byte dari data URI `data:<mime>;base64,<payload>`.
Uint8List? decodeDataUriBytes(String dataUri) {
  final comma = dataUri.indexOf(',');
  if (comma < 0) return null;
  final header = dataUri.substring(0, comma).toLowerCase();
  if (!header.contains(';base64')) return null;
  try {
    return base64Decode(dataUri.substring(comma + 1));
  } on FormatException {
    return null;
  }
}

/// Membungkus raw PCM 16-bit signed little-endian menjadi file WAV RIFF standar
/// agar dapat diputar langsung oleh `audioplayers` dengan callback selesai akurat.
Uint8List wrapPcmAsWav(
  Uint8List pcmBytes, {
  int sampleRate = 24000,
  int numChannels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final dataSize = pcmBytes.length;
  final totalSize = 36 + dataSize;

  final wav = Uint8List(44 + dataSize);
  final view = ByteData.view(wav.buffer);

  // RIFF chunk descriptor
  wav.setRange(0, 4, ascii.encode('RIFF'));
  view.setUint32(4, totalSize, Endian.little);
  wav.setRange(8, 12, ascii.encode('WAVE'));

  // fmt subchunk
  wav.setRange(12, 16, ascii.encode('fmt '));
  view.setUint32(16, 16, Endian.little); // PCM fmt chunk size
  view.setUint16(20, 1, Endian.little); // PCM linear quantization
  view.setUint16(22, numChannels, Endian.little);
  view.setUint32(24, sampleRate, Endian.little);
  view.setUint32(28, byteRate, Endian.little);
  view.setUint16(32, blockAlign, Endian.little);
  view.setUint16(34, bitsPerSample, Endian.little);

  // data subchunk
  wav.setRange(36, 40, ascii.encode('data'));
  view.setUint32(40, dataSize, Endian.little);
  wav.setRange(44, 44 + dataSize, pcmBytes);

  return wav;
}

String _extractInputText(List<Message> messages) {
  final buf = StringBuffer();
  for (final msg in messages) {
    for (final part in msg.content) {
      if (part.isText && part.text != null) {
        buf.write(part.text);
      }
    }
  }
  return buf.toString().trim();
}

Media? _extractInputMedia(List<Message> messages) {
  for (final msg in messages.reversed) {
    for (final part in msg.content) {
      if (part.isMedia && part.media != null) {
        return part.media;
      }
    }
  }
  return null;
}

GenkitException _mapHttpError(String source, int statusCode, String body) {
  final status = StatusCode.fromHttpStatus(statusCode);
  // Ambil ringkasan error yang aman (tanpa menyalin seluruh payload besar).
  var detail = 'HTTP $statusCode';
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final err = decoded['detail'] ?? decoded['error'] ?? decoded['message'];
      if (err is Map && err['message'] != null) {
        detail = 'HTTP $statusCode: ${err['message']}';
      } else if (err is String && err.trim().isNotEmpty) {
        detail = 'HTTP $statusCode: ${err.trim()}';
      }
    }
  } catch (_) {}
  return GenkitException('$source failed ($detail)', status: status);
}
