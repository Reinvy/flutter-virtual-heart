import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

/// On-device Text-to-Speech via [flutter_gemma_speech] (LiteRT C API).
///
/// Model TTS default: **Inflect-Nano-v2** (ringan, ~8 MB, cepat). Opsi:
/// **Matcha** (22050 Hz, lebih natural). Model di-download dari network
/// satu kali, lalu `synthesize` menghasilkan PCM 16-bit yang diputar via
/// [FlutterPcmSound].
class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  bool _ready = false;
  bool _isSpeaking = false;
  VoidCallback? _onComplete;
  Timer? _finishTimer;

  bool get isSpeaking => _isSpeaking;

  static const String _inflectBaseUrl =
      'https://huggingface.co/sasha-denisov/inflect-nano-v2-litert/resolve/main/';

  /// Memastikan model TTS terpasang; download dari network bila belum ada.
  ///
  /// [onProgress] dipanggil dengan persen (0..100) selama download.
  /// Kembali `false` bila gagal (mis. offline / dibatalkan).
  Future<bool> ensureReady({void Function(int percent)? onProgress}) async {
    if (_ready) return true;

    try {
      await FlutterGemma.installTts()
          .fromNetwork(_inflectBaseUrl)
          .withProgress((p) => onProgress?.call(p))
          .ofType(TtsModelType.inflect)
          .install();
      _ready = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Menyintesis [text] dan memutarnya. [onDone] dipanggil setelah selesai.
  Future<void> speak(String text, {VoidCallback? onDone}) async {
    if (text.trim().isEmpty) return;
    if (!await ensureReady()) {
      _onComplete = null;
      return;
    }

    _onComplete = onDone;

    try {
      final synth = await FlutterGemma.getActiveTts();
      final pcm = await synth.synthesize(text);

      if (pcm.isEmpty) {
        _finish();
        return;
      }

      // Inisialisasi player PCM dengan sample rate dari synthesizer.
      await FlutterPcmSound.setup(
        sampleRate: synth.sampleRate,
        channelCount: 1,
      );

      _isSpeaking = true;
      await FlutterPcmSound.feed(
        PcmArrayInt16(bytes: pcm.buffer.asByteData()),
      );
      FlutterPcmSound.start();

      // Estimasi durasi: 16-bit mono → byte/2 / sampleRate detik.
      final seconds = (pcm.length / 2 / synth.sampleRate).clamp(0.2, 120.0);
      _finishTimer?.cancel();
      _finishTimer = Timer(
        Duration(milliseconds: (seconds * 1000).round()),
        _finish,
      );
    } catch (_) {
      _finish();
    }
  }

  /// Menghentikan playback.
  Future<void> stop() async {
    _finishTimer?.cancel();
    _finishTimer = null;
    _onComplete = null;
    _isSpeaking = false;
    await FlutterPcmSound.release();
  }

  void _finish() {
    _finishTimer?.cancel();
    _finishTimer = null;
    _isSpeaking = false;
    final cb = _onComplete;
    _onComplete = null;
    cb?.call();
  }
}
