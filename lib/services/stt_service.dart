import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// On-device Speech-to-Text via [flutter_gemma_speech] (moonshine-tiny).
///
/// Rekam PCM 16 kHz mono 16-bit via [record] (tulis ke file sementara, karena
/// `startStream` belum diimplementasikan di record_linux), lalu transkrip dengan
/// [SpeechRecognizer.transcribe]. Model STT di-download dari network satu kali.
class SttService {
  SttService._internal();
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;

  final AudioRecorder _recorder = AudioRecorder();

  bool _ready = false;
  bool _isListening = false;
  String? _recordPath;

  bool get isListening => _isListening;
  bool get isAvailable => _ready;

  static const String _modelUrl =
      'https://huggingface.co/litert-community/moonshine-tiny/resolve/main/'
      'moonshine_tiny_5s_f32.tflite';
  static const String _tokenizerUrl =
      'https://huggingface.co/UsefulSensors/moonshine/resolve/main/'
      'ctranslate2/tiny/tokenizer.json';

  /// Memastikan model STT terpasang + izin mikrofon.
  ///
  /// [onProgress] dipanggil dengan persen (0..100) selama download.
  Future<bool> initialize({void Function(int percent)? onProgress}) async {
    if (_ready) return true;

    // Izin mikrofon.
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    try {
      // Instal model STT bila belum ada (id 'active_stt').
      final installed = await FlutterGemma.isModelInstalled('active_stt');
      if (!installed) {
        await FlutterGemma.installStt()
            .modelFromNetwork(_modelUrl)
            .tokenizerFromNetwork(_tokenizerUrl)
            .ofType(SttModelType.moonshine)
            .install();
      }
      _ready = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mulai merekam PCM 16 kHz mono 16-bit ke file sementara.
  Future<void> startListening() async {
    if (_isListening) return;
    if (!await initialize()) return;

    _isListening = true;

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

  /// Menghentikan rekaman dan mengembalikan hasil transkripsi.
  ///
  /// Mengembalikan string kosong bila tidak ada audio/transkrip.
  Future<String> stopListening() async {
    if (!_isListening) return '';

    _isListening = false;
    await _recorder.stop();

    final path = _recordPath;
    _recordPath = null;
    if (path == null) return '';

    try {
      // Baca file WAV dan buang header 44-byte → data PCM 16-bit.
      final file = File(path);
      final bytes = await file.readAsBytes();
      await file.delete().catchError((_) => file);

      final pcm = bytes.length > 44 ? bytes.sublist(44) : bytes;
      if (pcm.isEmpty) return '';

      final recognizer = await FlutterGemma.getActiveStt();
      return await recognizer.transcribe(Uint8List.fromList(pcm));
    } catch (_) {
      return '';
    }
  }

  /// Membatalkan sesi rekaman tanpa hasil.
  Future<void> cancel() async {
    _isListening = false;
    await _recorder.cancel();
    _recordPath = null;
  }
}
