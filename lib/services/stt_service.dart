import 'dart:async';
import 'dart:io';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/errors/app_logger.dart';
import '../core/utils/wav_pcm.dart';
import 'ai/speech_model_catalog.dart';

/// Facade Speech-to-Text dengan dua backend:
///
/// - **gemma** (`flutter_edge_ai_speech`): rekam PCM 16 kHz mono 16-bit via
///   [record] ke file WAV sementara, lalu transkrip dengan moonshine-tiny
///   melalui LiteRT C API. Rekaman ke file dipakai karena aliran byte
///   (`startStream`) tidak tersedia di semua platform desktop.
/// - **system** (`speech_to_text`): dikte sistem, tanpa unduhan model, dukung
///   banyak bahasa (termasuk Bahasa Indonesia).
class SttService {
  SttService._internal();
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;

  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _speech = SpeechToText();

  bool _localReady = false;
  bool _isListening = false;
  String? _recordPath;
  String _lastWords = '';

  bool get isListening => _isListening;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Memastikan backend siap.
  ///
  /// - `backend == 'system'`: init speech_to_text + izin mikrofon.
  /// - `backend == 'gemma'`: download model moonshine bila belum + izin mikrofon.
  ///
  /// [onProgress] menerima persen 0..100 saat model diunduh.
  Future<bool> initialize({
    String backend = 'gemma',
    void Function(int percent)? onProgress,
  }) async {
    if (backend == 'system') {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) return false;
      return _speech.initialize(
        onError: (_) => _isListening = false,
        onStatus: (status) {
          if (status == SpeechToText.notListeningStatus) _isListening = false;
        },
      );
    }

    if (_localReady && FlutterEdgeAi.hasActiveStt()) return true;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    try {
      if (!FlutterEdgeAi.hasActiveStt()) {
        await FlutterEdgeAi.installStt()
            .modelFromNetwork(kSttModelUrl)
            .tokenizerFromNetwork(kSttTokenizerUrl)
            .ofType(sttModelById('moonshine').edgeAiSttType!)
            .withProgress((p) => onProgress?.call(p))
            .install();
      }
      _localReady = true;
      return true;
    } catch (e) {
      AppLogger.debug('STT model unavailable', e);
      return false;
    }
  }

  /// Mulai mendengarkan sesuai [backend].
  ///
  /// [languageCode] (mis. `id-ID`/`en-US`) hanya dipakai backend sistem.
  Future<void> startListening({String backend = 'gemma', String? languageCode}) async {
    if (_isListening) return;
    if (!await initialize(backend: backend)) return;

    _isListening = true;

    if (backend == 'system') {
      _lastWords = '';
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
          localeId: _systemLocale(languageCode),
        ),
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      _recordPath = '${dir.path}/vh_stt_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordPath!,
      );
    } catch (e) {
      AppLogger.debug('STT recording failed', e);
      _isListening = false;
    }
  }

  /// Menghentikan dan mengembalikan transkripsi sesuai [backend].
  Future<String> stopListening({String backend = 'gemma', String? languageCode}) async {
    if (!_isListening) return '';
    _isListening = false;

    if (backend == 'system') {
      await _speech.stop();
      return _lastWords.trim();
    }

    await _recorder.stop();

    final path = _recordPath;
    _recordPath = null;
    if (path == null) return '';

    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      await file.delete().catchError((_) => file);

      final pcm = pcmFromWav(bytes);
      if (pcm.isEmpty) return '';

      final recognizer = await FlutterEdgeAi.getActiveStt();
      return (await recognizer.transcribe(pcm)).trim();
    } catch (e) {
      AppLogger.debug('STT transcription failed', e);
      return '';
    }
  }

  /// Membatalkan sesi tanpa hasil.
  Future<void> cancel() async {
    _isListening = false;
    await _speech.cancel();
    await _recorder.cancel();
    _recordPath = null;
  }

  /// `speech_to_text` memakai format locale `ll_CC` (underscore).
  static String _systemLocale(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) return 'id_ID';
    return languageCode.replaceAll('-', '_');
  }
}
