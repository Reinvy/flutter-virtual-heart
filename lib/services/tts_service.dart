import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/persona_config.dart';
import 'ai/speech_model_catalog.dart';

/// Facade Text-to-Speech dengan dua backend:
///
/// - **gemma** (`flutter_gemma_speech`): synthesize on-device (model terpilih:
///   Inflect / Matcha / Qwen3) → PCM 16-bit → [FlutterPcmSound].
/// - **system** (`flutter_tts`): suara sistem, tanpa unduhan model, dukung
///   banyak bahasa (termasuk Bahasa Indonesia).
class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  bool _gemmaReady = false;
  bool _isSpeaking = false;
  VoidCallback? _onComplete;
  Timer? _finishTimer;

  bool get isSpeaking => _isSpeaking;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Memastikan backend siap.
  ///
  /// - `backend == 'system'`: init flutter_tts.
  /// - `backend == 'gemma'`: download model [model] bila belum terpasang.
  ///
  /// Kembali `false` bila gagal.
  Future<bool> ensureReady({
    String backend = 'gemma',
    String model = 'inflect',
    void Function(int percent)? onProgress,
  }) async {
    if (backend == 'system') {
      return _initSystemTts();
    }
    if (_gemmaReady) return true;

    final option = ttsModelById(model);
    try {
      await FlutterGemma.installTts()
          .fromNetwork(option.baseUrl!)
          .withProgress((p) => onProgress?.call(p))
          .ofType(option.gemmaTtsType!)
          .install();
      _gemmaReady = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Menyintesis [text] dan memutarnya sesuai [backend] & [gender].
  Future<void> speak(
    String text, {
    String backend = 'gemma',
    String model = 'inflect',
    PersonaGender? gender,
    VoidCallback? onDone,
  }) async {
    if (text.trim().isEmpty) return;

    if (backend == 'system') {
      await _speakSystem(text, gender: gender, onDone: onDone);
      return;
    }

    if (!await ensureReady(backend: backend, model: model)) {
      _onComplete = null;
      return;
    }
    await _speakGemma(text, onDone: onDone);
  }

  /// Menghentikan playback.
  Future<void> stop() async {
    _finishTimer?.cancel();
    _finishTimer = null;
    _onComplete = null;
    _isSpeaking = false;
    await _flutterTts.stop();
    await FlutterPcmSound.release();
  }

  // ── Backend: system (flutter_tts) ───────────────────────────────────────

  Future<bool> _initSystemTts() async {
    _flutterTts.setStartHandler(() => _isSpeaking = true);
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      final cb = _onComplete;
      _onComplete = null;
      cb?.call();
    });
    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      _onComplete = null;
    });
    _flutterTts.setErrorHandler((_) {
      _isSpeaking = false;
      _onComplete = null;
    });
    return true;
  }

  Future<void> _speakSystem(
    String text, {
    PersonaGender? gender,
    VoidCallback? onDone,
  }) async {
    await _initSystemTts();
    await _flutterTts.stop();

    _onComplete = onDone;
    _isSpeaking = true;

    // Prefer bahasa Indonesia; fallback Inggris.
    await _flutterTts.setLanguage('id-ID');
    if (gender == PersonaGender.girlfriend) {
      await _flutterTts.setPitch(1.6);
      await _flutterTts.setSpeechRate(0.4);
    } else {
      await _flutterTts.setPitch(0.88);
      await _flutterTts.setSpeechRate(0.47);
    }

    await _flutterTts.speak(text);
  }

  // ── Backend: gemma (flutter_gemma_speech) ───────────────────────────────

  Future<void> _speakGemma(String text, {VoidCallback? onDone}) async {
    _onComplete = onDone;

    try {
      final synth = await FlutterGemma.getActiveTts();
      final pcm = await synth.synthesize(text);

      if (pcm.isEmpty) {
        _finish();
        return;
      }

      await FlutterPcmSound.setup(
        sampleRate: synth.sampleRate,
        channelCount: 1,
      );

      _isSpeaking = true;
      await FlutterPcmSound.feed(PcmArrayInt16(bytes: pcm.buffer.asByteData()));
      FlutterPcmSound.start();

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

  void _finish() {
    _finishTimer?.cancel();
    _finishTimer = null;
    _isSpeaking = false;
    final cb = _onComplete;
    _onComplete = null;
    cb?.call();
  }
}
