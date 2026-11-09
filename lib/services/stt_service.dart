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

/// Hasil memulai sesi dikte.
enum SttStartResult { started, permissionDenied, unavailable, busy }

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
  bool _starting = false;
  String? _recordPath;
  String _lastWords = '';

  bool get isListening => _isListening;

  /// `true` bila model on-device [model] sedang aktif di engine.
  bool isModelActive(String model) =>
      model == 'moonshine' && _localReady && FlutterEdgeAi.hasActiveStt();

  // ── Public API ───────────────────────────────────────────────────────────

  /// Memastikan backend siap (izin mikrofon + model/engine).
  ///
  /// [onProgress] menerima persen 0..100 saat model diunduh.
  Future<bool> initialize({
    String backend = 'system',
    void Function(int percent)? onProgress,
  }) async {
    final granted = await _requestMicrophone();
    if (!granted) return false;
    return _prepare(backend: backend, onProgress: onProgress);
  }

  /// Mulai mendengarkan sesuai [backend].
  ///
  /// [languageCode] (mis. `id-ID`/`en-US`) hanya dipakai backend sistem.
  Future<SttStartResult> startListening({
    String backend = 'system',
    String? languageCode,
  }) async {
    if (_isListening || _starting) return SttStartResult.busy;
    _starting = true;
    try {
      final granted = await _requestMicrophone();
      if (!granted) return SttStartResult.permissionDenied;

      final ready = await _prepare(backend: backend);
      if (!ready) return SttStartResult.unavailable;

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
        _isListening = true;
        return SttStartResult.started;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/vh_stt_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      _recordPath = path;
      _isListening = true;
      return SttStartResult.started;
    } catch (e) {
      AppLogger.debug('STT start failed', e);
      _isListening = false;
      await _deleteRecording();
      return SttStartResult.unavailable;
    } finally {
      _starting = false;
    }
  }

  /// Menghentikan dan mengembalikan transkripsi sesuai [backend].
  Future<String> stopListening({String backend = 'system', String? languageCode}) async {
    if (!_isListening) return '';
    _isListening = false;

    try {
      if (backend == 'system') {
        await _speech.stop();
        return _lastWords.trim();
      }

      await _recorder.stop();

      final path = _recordPath;
      _recordPath = null;
      if (path == null) return '';

      final file = File(path);
      final bytes = await file.readAsBytes();

      final pcm = pcmFromWav(bytes);
      if (pcm.isEmpty) return '';

      final recognizer = await FlutterEdgeAi.getActiveStt();
      return (await recognizer.transcribe(pcm)).trim();
    } catch (e) {
      AppLogger.debug('STT transcription failed', e);
      return '';
    } finally {
      await _deleteRecording();
    }
  }

  /// Membatalkan sesi tanpa hasil.
  Future<void> cancel() async {
    _isListening = false;
    try {
      await _speech.cancel();
    } catch (e) {
      AppLogger.debug('STT cancel failed', e);
    }
    try {
      await _recorder.cancel();
    } catch (e) {
      AppLogger.debug('Recorder cancel failed', e);
    } finally {
      await _deleteRecording();
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────

  Future<bool> _requestMicrophone() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted || status.isLimited;
    } catch (e) {
      AppLogger.debug('Microphone permission failed', e);
      return false;
    }
  }

  Future<bool> _prepare({
    required String backend,
    void Function(int percent)? onProgress,
  }) async {
    if (backend == 'system') {
      try {
        return await _speech.initialize(
          onError: (_) => _isListening = false,
          onStatus: (status) {
            if (status == SpeechToText.notListeningStatus) _isListening = false;
          },
        );
      } catch (e) {
        AppLogger.debug('System STT init failed', e);
        return false;
      }
    }

    if (_localReady && FlutterEdgeAi.hasActiveStt()) return true;

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

  /// Menghapus file rekaman sementara (best-effort, tanpa melempar).
  Future<void> _deleteRecording() async {
    final path = _recordPath;
    _recordPath = null;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.debug('Temp recording cleanup failed', e);
    }
  }

  /// `speech_to_text` memakai format locale `ll_CC` (underscore).
  static String _systemLocale(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) return 'id_ID';
    return languageCode.replaceAll('-', '_');
  }
}
