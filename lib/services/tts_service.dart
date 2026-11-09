import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/errors/app_logger.dart';
import '../models/persona_config.dart';
import 'ai/speech_model_catalog.dart';

/// Facade Text-to-Speech dengan dua backend:
///
/// - **gemma** (`flutter_edge_ai_speech`): synthesize on-device (model terpilih:
///   Inflect / Matcha / Qwen3) → PCM 16-bit → [FlutterPcmSound].
/// - **system** (`flutter_tts`): suara sistem, tanpa unduhan model, dukung
///   banyak bahasa (termasuk Bahasa Indonesia).
///
/// Instance ini singleton sepanjang umur proses; [FlutterPcmSound] dilepas di
/// [stop] dan tidak perlu `dispose` terpisah.
class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();

  /// Model on-device yang sudah terpasang & aktif (null bila belum).
  String? _readyModel;
  VoidCallback? _onComplete;
  Timer? _finishTimer;

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
    if (_readyModel == model && FlutterEdgeAi.hasActiveTts()) return true;

    final option = ttsModelById(model);
    try {
      await FlutterEdgeAi.installTts()
          .fromNetwork(option.baseUrl!)
          .withProgress((p) => onProgress?.call(p))
          .ofType(option.edgeAiTtsType!)
          .install();
      _readyModel = model;
      return true;
    } catch (e) {
      _readyModel = null;
      AppLogger.debug('TTS model unavailable', e);
      return false;
    }
  }

  /// Menyintesis [text] dan memutarnya sesuai [backend] & [gender].
  ///
  /// [languageCode] (mis. `id-ID`/`en-US`) dipakai backend sistem.
  Future<void> speak(
    String text, {
    String backend = 'gemma',
    String model = 'inflect',
    PersonaGender? gender,
    String? languageCode,
    VoidCallback? onDone,
  }) async {
    if (text.trim().isEmpty) return;

    if (backend == 'system') {
      await _speakSystem(
        text,
        gender: gender,
        languageCode: languageCode,
        onDone: onDone,
      );
      return;
    }

    if (!await ensureReady(backend: backend, model: model)) {
      _onComplete = null;
      return;
    }
    await _speakOnDevice(text, onDone: onDone);
  }

  /// Menghentikan playback.
  Future<void> stop() async {
    _finishTimer?.cancel();
    _finishTimer = null;
    _onComplete = null;
    await _flutterTts.stop();
    await FlutterPcmSound.release();
  }

  // ── Backend: system (flutter_tts) ───────────────────────────────────────

  Future<bool> _initSystemTts() async {
    _flutterTts.setStartHandler(() {});
    _flutterTts.setCompletionHandler(() {
      final cb = _onComplete;
      _onComplete = null;
      cb?.call();
    });
    _flutterTts.setCancelHandler(() {
      _onComplete = null;
    });
    _flutterTts.setErrorHandler((_) {
      _onComplete = null;
    });
    return true;
  }

  Future<void> _speakSystem(
    String text, {
    PersonaGender? gender,
    String? languageCode,
    VoidCallback? onDone,
  }) async {
    await _initSystemTts();
    await _flutterTts.stop();

    _onComplete = onDone;

    await _flutterTts.setLanguage(languageCode ?? 'id-ID');
    if (gender == PersonaGender.girlfriend) {
      await _flutterTts.setPitch(1.6);
      await _flutterTts.setSpeechRate(0.4);
    } else {
      await _flutterTts.setPitch(0.88);
      await _flutterTts.setSpeechRate(0.47);
    }

    await _flutterTts.speak(text);
  }

  // ── Backend: on-device (flutter_edge_ai_speech) ─────────────────────────

  Future<void> _speakOnDevice(String text, {VoidCallback? onDone}) async {
    _onComplete = onDone;

    try {
      final synth = await FlutterEdgeAi.getActiveTts();
      final pcm = await synth.synthesize(text);

      if (pcm.isEmpty) {
        _finish();
        return;
      }

      await FlutterPcmSound.setup(
        sampleRate: synth.sampleRate,
        channelCount: 1,
      );

      await FlutterPcmSound.feed(PcmArrayInt16(bytes: pcm.buffer.asByteData()));
      FlutterPcmSound.start();

      // Belum ada callback "playback selesai" dari plugin PCM: durasi audio
      // dihitung dari panjang PCM (catat sebagai known issue).
      final seconds = (pcm.length / 2 / synth.sampleRate).clamp(0.2, 120.0);
      _finishTimer?.cancel();
      _finishTimer = Timer(
        Duration(milliseconds: (seconds * 1000).round()),
        _finish,
      );
    } catch (e) {
      AppLogger.debug('TTS playback failed', e);
      _finish();
    }
  }

  void _finish() {
    _finishTimer?.cancel();
    _finishTimer = null;
    final cb = _onComplete;
    _onComplete = null;
    cb?.call();
  }
}
