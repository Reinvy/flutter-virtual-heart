// Unit test — GenkitCloudClient (OpenAI-compat, Anthropic-compat, discovery, speech, cancel).
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart' as gk;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:virtual_heart/models/ai_provider_profile.dart';
import 'package:virtual_heart/models/cloud_speech_config.dart';
import 'package:virtual_heart/models/message.dart';
import 'package:virtual_heart/services/ai/genkit/elevenlabs_plugin.dart';
import 'package:virtual_heart/services/ai/genkit/genkit_cloud_client.dart';
import 'package:virtual_heart/services/ai/prompt_builder.dart';

void main() {
  group('GenkitCloudClient LLM', () {
    test('OpenAI-compatible streaming mengalirkan token & stripStreamOptions bekerja', () async {
      Map<String, dynamic>? capturedBody;
      Map<String, String>? capturedHeaders;
      Uri? capturedUri;

      final client = GenkitCloudClient(
        httpClientFactory: () => MockClient.streaming((request, bodyStream) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          final raw = await bodyStream.bytesToString();
          capturedBody = jsonDecode(raw) as Map<String, dynamic>;

          final sse = [
            'data: ${jsonEncode({
              'id': 'chatcmpl-1',
              'object': 'chat.completion.chunk',
              'created': 1700000000,
              'model': 'llama3.2',
              'choices': [
                {'index': 0, 'delta': {'role': 'assistant', 'content': 'Halo '}, 'finish_reason': null},
              ],
            })}\n\n',
            'data: ${jsonEncode({
              'id': 'chatcmpl-1',
              'object': 'chat.completion.chunk',
              'created': 1700000000,
              'model': 'llama3.2',
              'choices': [
                {'index': 0, 'delta': {'content': 'sayang!'}, 'finish_reason': 'stop'},
              ],
            })}\n\n',
            'data: [DONE]\n\n',
          ];

          return http.StreamedResponse(
            Stream.fromIterable(sse.map(utf8.encode)),
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }),
      );

      final profile = AiProviderProfile(
        profileKey: 'ollama_1',
        name: 'Local Ollama',
        providerType: LlmProviderType.openai,
        baseUrl: 'http://localhost:11434/v1',
        modelId: 'llama3.2',
        customHeadersJson: '{"X-App": "VirtualHeart"}',
        stripStreamOptions: true,
        temperature: 0.7,
        maxOutputTokens: 512,
      );

      final chunks = await client
          .streamChat(
            profile: profile,
            apiKey: '', // Diizinkan karena localhost!
            systemPrompt: 'Kamu adalah Luna.',
            messages: const [
              CloudChatTurn(role: MessageRole.user, content: 'Hai Luna'),
            ],
          )
          .toList();

      expect(chunks.join(), 'Halo sayang!');
      expect(capturedUri.toString(), 'http://localhost:11434/v1/chat/completions');
      expect(capturedHeaders?['X-App'], 'VirtualHeart');
      expect(capturedBody?.containsKey('stream_options'), isFalse);
    });

    test('Anthropic-compatible streaming dengan custom baseUrl & header mengalirkan token', () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;

      final client = GenkitCloudClient(
        httpClientFactory: () => MockClient.streaming((request, bodyStream) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          await bodyStream.drain<void>();

          final sse = [
            'event: message_start\ndata: ${jsonEncode({
              'type': 'message_start',
              'message': {
                'id': 'msg_1',
                'type': 'message',
                'role': 'assistant',
                'content': <Object>[],
                'model': 'claude-sonnet-4-6',
                'stop_reason': null,
                'stop_sequence': null,
                'usage': {'input_tokens': 10, 'output_tokens': 1},
              },
            })}\n\n',
            'event: content_block_start\ndata: ${jsonEncode({
              'type': 'content_block_start',
              'index': 0,
              'content_block': {'type': 'text', 'text': ''},
            })}\n\n',
            'event: content_block_delta\ndata: ${jsonEncode({
              'type': 'content_block_delta',
              'index': 0,
              'delta': {'type': 'text_delta', 'text': 'Selamat malam '},
            })}\n\n',
            'event: content_block_delta\ndata: ${jsonEncode({
              'type': 'content_block_delta',
              'index': 0,
              'delta': {'type': 'text_delta', 'text': 'sayang.'},
            })}\n\n',
            'event: content_block_stop\ndata: ${jsonEncode({
              'type': 'content_block_stop',
              'index': 0,
            })}\n\n',
            'event: message_delta\ndata: ${jsonEncode({
              'type': 'message_delta',
              'delta': {'stop_reason': 'end_turn', 'stop_sequence': null},
              'usage': {'output_tokens': 5},
            })}\n\n',
            'event: message_stop\ndata: ${jsonEncode({'type': 'message_stop'})}\n\n',
          ];

          return http.StreamedResponse(
            Stream.fromIterable(sse.map(utf8.encode)),
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }),
      );

      final profile = AiProviderProfile(
        profileKey: 'anth_1',
        name: 'Anthropic Proxy',
        providerType: LlmProviderType.anthropic,
        baseUrl: 'https://proxy.anthropic.example/v1',
        modelId: 'claude-sonnet-4-6',
        customHeadersJson: '{"X-Custom-Proxy": "yes"}',
      );

      final chunks = await client
          .streamChat(
            profile: profile,
            apiKey: 'sk-ant-test',
            systemPrompt: 'Kamu adalah Luna.',
            messages: const [
              CloudChatTurn(role: MessageRole.user, content: 'Malam Luna'),
            ],
          )
          .toList();

      expect(chunks.join(), 'Selamat malam sayang.');
      expect(capturedUri.toString(), 'https://proxy.anthropic.example/v1/messages');
      expect(capturedHeaders?['x-api-key'], 'sk-ant-test');
      expect(capturedHeaders?['X-Custom-Proxy'], 'yes');
    });

    test('membatalkan CancellationController sebelum request menghentikan stream tanpa error', () async {
      final client = GenkitCloudClient(
        httpClientFactory: () => MockClient((_) async {
          fail('HTTP tidak boleh dipanggil setelah dibatalkan');
        }),
      );

      final cancel = gk.CancellationController()..cancel('user stop');
      final profile = AiProviderProfile(
        profileKey: 'o1',
        name: 'OpenAI',
        providerType: LlmProviderType.openai,
        modelId: 'gpt-4o-mini',
      );

      final chunks = await client
          .streamChat(
            profile: profile,
            apiKey: 'sk-test',
            systemPrompt: 'Sys',
            messages: const [CloudChatTurn(role: MessageRole.user, content: 'Hi')],
            cancellation: cancel,
          )
          .toList();

      expect(chunks, isEmpty);
    });

    test('fetchAvailableModels mem-parse respons Google, Anthropic, dan OpenAI', () async {
      final googleClient = GenkitCloudClient(
        httpClientFactory: () => MockClient((req) async {
          expect(req.url.path, '/v1beta/models');
          expect(req.headers['x-goog-api-key'], 'g-key');
          return http.Response(
            jsonEncode({
              'models': [
                {
                  'name': 'models/gemini-2.5-flash',
                  'supportedGenerationMethods': ['generateContent'],
                },
                {
                  'name': 'models/embedding-001',
                  'supportedGenerationMethods': ['embedContent'],
                },
              ],
            }),
            200,
          );
        }),
      );

      final gModels = await googleClient.fetchAvailableModels(
        providerType: LlmProviderType.google,
        apiKey: 'g-key',
      );
      expect(gModels, ['gemini-2.5-flash']);

      final openaiClient = GenkitCloudClient(
        httpClientFactory: () => MockClient((req) async {
          expect(req.url.toString(), 'https://openrouter.ai/api/v1/models');
          expect(req.headers['Authorization'], 'Bearer or-key');
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'openai/gpt-4o'},
                {'id': 'anthropic/claude-sonnet-4.6'},
              ],
            }),
            200,
          );
        }),
      );

      final oModels = await openaiClient.fetchAvailableModels(
        providerType: LlmProviderType.openai,
        apiKey: 'or-key',
        baseUrl: 'https://openrouter.ai/api/v1/',
      );
      expect(oModels, ['anthropic/claude-sonnet-4.6', 'openai/gpt-4o']);
    });

    test('menolak API key kosong pada endpoint publik (non-localhost)', () async {
      final client = GenkitCloudClient(
        httpClientFactory: () => MockClient((_) async => http.Response('', 200)),
      );
      final profile = AiProviderProfile(
        profileKey: 'o1',
        name: 'OpenAI',
        providerType: LlmProviderType.openai,
        modelId: 'gpt-4o',
      );

      final result = await client.testConnection(profile: profile, apiKey: '');
      expect(result.ok, isFalse);
      expect(result.error, isA<gk.GenkitException>());
    });

    test('HTTP 401 pada ElevenLabs TTS lewat GenkitCloudClient melempar GenkitException(unauthenticated)', () async {
      final client = GenkitCloudClient(
        httpClientFactory: () => MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': {'message': 'Invalid API key'}}),
            401,
          ),
        ),
      );

      await expectLater(
        client.synthesizeSpeech(
          backend: 'elevenlabs',
          config: CloudSpeechConfig(),
          apiKey: 'bad-key',
          text: 'Halo',
        ),
        throwsA(
          isA<gk.GenkitException>().having(
            (e) => e.status,
            'status',
            gk.StatusCode.unauthenticated,
          ),
        ),
      );
    });
  });

  group('GenkitCloudClient Cloud Speech', () {
    test('synthesizeSpeech ElevenLabs PCM otomatis dibungkus menjadi WAV', () async {
      final pcm = Uint8List.fromList([1, 0, 2, 0, 3, 0, 4, 0]);
      final client = GenkitCloudClient(
        httpClientFactory: () => MockClient((req) async {
          return http.Response.bytes(
            pcm,
            200,
            headers: {'content-type': 'audio/pcm'},
          );
        }),
      );

      final audio = await client.synthesizeSpeech(
        backend: 'elevenlabs',
        config: CloudSpeechConfig(elevenLabsOutputFormat: 'pcm_24000'),
        apiKey: 'el-key',
        text: 'Halo dunia',
      );

      expect(audio.mimeType, 'audio/wav');
      expect(audio.fileExtension, 'wav');
      expect(audio.bytes.length, 44 + pcm.length);
    });

    test('transcribeAudio OpenAI-compatible melalui Genkit mengembalikan transkrip', () async {
      Uri? capturedUri;
      final client = GenkitCloudClient(
        httpClientFactory: () => MockClient.streaming((req, bodyStream) async {
          capturedUri = req.url;
          await bodyStream.drain<void>();
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({'text': 'Terima kasih ya'}))),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final wav = wrapPcmAsWav(Uint8List.fromList([0, 0, 1, 0]), sampleRate: 16000);
      final text = await client.transcribeAudio(
        backend: 'openai',
        config: CloudSpeechConfig(
          openaiSttBaseUrl: 'https://api.groq.com/openai/v1',
          openaiSttModel: 'whisper-large-v3-turbo',
        ),
        apiKey: 'gsk-test',
        wavBytes: wav,
        languageCode: 'id-ID',
      );

      expect(capturedUri.toString(), 'https://api.groq.com/openai/v1/audio/transcriptions');
      expect(text, 'Terima kasih ya');
    });
  });
}
