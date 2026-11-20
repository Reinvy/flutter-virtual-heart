// Unit test — custom ElevenLabsGenkitPlugin (TTS, STT Scribe, Voices, WAV wrap, errors).
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart' as gk;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:virtual_heart/core/utils/wav_pcm.dart';
import 'package:virtual_heart/services/ai/genkit/elevenlabs_plugin.dart';

void main() {
  group('ElevenLabsGenkitPlugin via Genkit', () {
    test('TTS mengirim xi-api-key, output_format, voice_settings, dan mengembalikan MediaPart', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      late Map<String, dynamic> capturedBody;
      final fakeMp3 = Uint8List.fromList([0x49, 0x44, 0x33, 0x03, 0x00, 0x01]);

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response.bytes(
          fakeMp3,
          200,
          headers: {'content-type': 'audio/mpeg'},
        );
      });

      final ai = gk.Genkit(
        plugins: [
          elevenLabs(
            apiKey: 'el-test-key',
            baseUrl: 'https://api.elevenlabs.io/v1/',
            httpClient: mockClient,
          ),
        ],
        isDevEnv: false,
        promptDir: null,
      );
      addTearDown(ai.shutdown);

      final result = await ai.generate(
        model: elevenLabs.ttsModel('eleven_multilingual_v2'),
        prompt: 'Halo sayang, selamat pagi!',
        config: {
          'voiceId': 'voice_abc',
          'outputFormat': 'mp3_44100_128',
          'stability': 0.45,
          'similarityBoost': 0.8,
          'style': 0.0, // harus dihilangkan saat 0.0
          'speed': 1.05,
          'useSpeakerBoost': true,
        },
      );

      expect(
        capturedUri.toString(),
        'https://api.elevenlabs.io/v1/text-to-speech/voice_abc?output_format=mp3_44100_128',
      );
      expect(capturedHeaders['xi-api-key'], 'el-test-key');
      expect(capturedBody['model_id'], 'eleven_multilingual_v2');
      expect(capturedBody['text'], 'Halo sayang, selamat pagi!');
      final vs = capturedBody['voice_settings'] as Map<String, dynamic>;
      expect(vs['stability'], 0.45);
      expect(vs['similarity_boost'], 0.8);
      expect(vs.containsKey('style'), isFalse);
      expect(vs['speed'], 1.05);
      expect(vs['use_speaker_boost'], isTrue);

      expect(result.media, isNotNull);
      expect(result.media!.contentType, 'audio/mpeg');
      expect(decodeDataUriBytes(result.media!.url), fakeMp3);
    });

    test('STT Scribe mengirim multipart WAV dan mengekstrak transkrip', () async {
      String? capturedKey;
      String? capturedPath;
      String? capturedRawBody;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        capturedKey = request.headers['xi-api-key'];
        capturedPath = request.url.path;
        capturedRawBody = latin1.decode(await bodyStream.toBytes());
        final respBytes = utf8.encode(jsonEncode({'text': 'Halo apa kabar hari ini'}));
        return http.StreamedResponse(
          Stream.value(respBytes),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final ai = gk.Genkit(
        plugins: [
          elevenLabs(apiKey: 'el-stt-key', httpClient: mockClient),
        ],
        isDevEnv: false,
        promptDir: null,
      );
      addTearDown(ai.shutdown);

      final wav = wrapPcmAsWav(Uint8List.fromList([0, 0, 1, 0, 2, 0]), sampleRate: 16000);
      final result = await ai.generate(
        model: elevenLabs.sttModel('scribe_v2'),
        promptParts: [
          gk.MediaPart(
            media: gk.Media(
              url: 'data:audio/wav;base64,${base64Encode(wav)}',
              contentType: 'audio/wav',
            ),
          ),
        ],
        config: {
          'languageCode': 'id-ID',
          'tagAudioEvents': true,
          'diarize': false,
        },
      );

      expect(capturedKey, 'el-stt-key');
      expect(capturedPath, '/v1/speech-to-text');
      expect(capturedRawBody, contains('scribe_v2'));
      expect(capturedRawBody, contains('name="language_code"'));
      expect(capturedRawBody, contains('id'));
      expect(result.text, 'Halo apa kabar hari ini');
    });

    test('HTTP 401 dan 429 menghasilkan GenerateResult gagal dengan StatusCode tepat', () async {
      final unauthClient = MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': {'message': 'Invalid API key'}}),
          401,
        ),
      );
      final ai401 = gk.Genkit(
        plugins: [elevenLabs(apiKey: 'bad', httpClient: unauthClient)],
        isDevEnv: false,
        promptDir: null,
      );
      addTearDown(ai401.shutdown);

      final res401 = await ai401.generate(
        model: elevenLabs.ttsModel('eleven_multilingual_v2'),
        prompt: 'Hi',
        config: {'voiceId': 'v1'},
      );
      expect(res401.finishReason, gk.FinishReason.failed);
      expect(res401.error?.status, gk.StatusCode.unauthenticated.wireName);

      final rateClient = MockClient((_) async => http.Response('Too many requests', 429));
      final ai429 = gk.Genkit(
        plugins: [elevenLabs(apiKey: 'k', httpClient: rateClient)],
        isDevEnv: false,
        promptDir: null,
      );
      addTearDown(ai429.shutdown);

      final res429 = await ai429.generate(
        model: elevenLabs.ttsModel('eleven_multilingual_v2'),
        prompt: 'Hi',
        config: {'voiceId': 'v1'},
      );
      expect(res429.finishReason, gk.FinishReason.failed);
      expect(res429.error?.status, gk.StatusCode.resourceExhausted.wireName);
    });

    test('ElevenLabsVoicesApi.fetchVoices mem-parse daftar suara dengan bersih', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/v1/voices');
        expect(request.headers['xi-api-key'], 'el-key');
        return http.Response(
          jsonEncode({
            'voices': [
              {
                'voice_id': 'v_1',
                'name': 'Sarah',
                'category': 'premade',
                'labels': {'accent': 'american', 'age': 'young'},
              },
              {'voice_id': '', 'name': 'Invalid'},
            ],
          }),
          200,
        );
      });

      final voices = await ElevenLabsVoicesApi.fetchVoices(
        apiKey: 'el-key',
        httpClient: mockClient,
      );
      expect(voices.length, 1);
      expect(voices.first.voiceId, 'v_1');
      expect(voices.first.name, 'Sarah');
      expect(voices.first.description, contains('american'));
    });

    test('wrapPcmAsWav menghasilkan header RIFF WAV valid yang bisa dibaca pcmFromWav', () {
      final rawPcm = Uint8List.fromList([10, 0, 20, 0, 30, 0, 40, 0]);
      final wav = wrapPcmAsWav(rawPcm, sampleRate: 24000);
      expect(wav.length, 44 + rawPcm.length);
      expect(pcmFromWav(wav), rawPcm);
    });
  });
}
