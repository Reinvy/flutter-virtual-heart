import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'ai/speech_model_catalog.dart';

/// Facade Speech-to-Text dengan dua backend:
///
/// - **gemma** (`flutter_gemma_speech`): rekam PCM 16 kHz mono 16-bit via
///   [record] (tulis ke file sementara, karena `startStream` belum ada di
///   record_linux), lalu transkrip dengan moonshine-tiny.
/// - **system** (`speech_to_text`): dikte sistem, tanpa unduhan model, dukung
///   banyak bahasa (termasuk Bahasa Indonesia).
class SttService {
  SttService._internal();
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;

  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _speech = SpeechToText();

  bool _gemmaReady = false;
  bool _isListening = false;
  String? _recordPath;
  String _lastWords = '';

  bool get isListening => _isListening;
  bool get isAvailable => _gemmaReady || _speech.isAvailable;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Memastikan backend siap.
  ///
  /// - `backend == 'system'`: init speech_to_text + izin mikrofon.
  /// - `backend == 'gemma'`: download model moonshine bila belum + izin mikrofon.
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

    if (_gemmaReady) return true;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    try {
      final installed = await FlutterGemma.isModelInstalled('active_stt');
      if (!installed) {
        await FlutterGemma.installStt()
            .modelFromNetwork(kSttModelUrl)
            .tokenizerFromNetwork(kSttTokenizerUrl)
            .ofType(sttModelById('moonshine').gemmaSttType!)
            .install();
      }
      _gemmaReady = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mulai mendengarkan sesuai [backend].
  Future<void> startListening({String backend = 'gemma'}) async {
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
          localeId: 'id_ID',
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
    } catch (_) {
      _isListening = false;
    }
  }

  /// Menghentikan dan mengembalikan transkripsi sesuai [backend].
  Future<String> stopListening({String backend = 'gemma'}) async {
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

      final pcm = bytes.length > 44 ? bytes.sublist(44) : bytes;
      if (pcm.isEmpty) return '';

      final recognizer = await FlutterGemma.getActiveStt();
      return (await recognizer.transcribe(Uint8List.fromList(pcm))).trim();
    } catch (_) {
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
}
