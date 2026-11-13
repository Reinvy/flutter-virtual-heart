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
///
/// Setiap utterance diberi nomor urut. `stop()` menaikkan nomor tersebut
/// sehingga sintesis yang masih berjalan tahu dirinya sudah basi dan tidak
/// menimpa playback baru.
class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();

  /// Model on-device yang sudah terpasang & aktif (null bila belum).
  String? _readyModel;
  VoidCallback? _onComplete;
  Timer? _finishTimer;
  int _utterance = 0;
  int _activeSystemId = 0;
  bool _systemTtsInitialized = false;
  Future<bool>? _ensuringFuture;
  String? _ensuringModel;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Memastikan backend siap.
  ///
  /// - `backend == 'system'`: init flutter_tts.
  /// - `backend == 'gemma'`: download model [model] bila belum terpasang.
  ///
  /// Kembali `false` bila gagal.
  Future<bool> ensureReady({
    String backend = 'system',
    String model = 'inflect',
    void Function(int percent)? onProgress,
  }) async {
    if (backend == 'system') {
      return _initSystemTts();
    }
    if (_readyModel == model && FlutterEdgeAi.hasActiveTts()) return true;

    while (_ensuringFuture != null) {
      if (_ensuringModel == model) return _ensuringFuture!;
      try {
        await _ensuringFuture;
      } catch (_) {}
    }

    final future = _installOnDeviceModel(model, onProgress: onProgress);
    _ensuringModel = model;
    _ensuringFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_ensuringFuture, future)) {
        _ensuringFuture = null;
        _ensuringModel = null;
      }
    }
  }

  Future<bool> _installOnDeviceModel(
    String model, {
    void Function(int percent)? onProgress,
  }) async {
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

  /// `true` bila model on-device [model] sedang aktif di engine.
  bool isModelActive(String model) => _readyModel == model && FlutterEdgeAi.hasActiveTts();

  /// Menyintesis [text] dan memutarnya sesuai [backend] & [gender].
  ///
  /// [languageCode] (mis. `id-ID`/`en-US`) dipakai backend sistem dan diteruskan
  /// ke engine on-device.
  Future<bool> speak(
    String text, {
    String backend = 'system',
    String model = 'inflect',
    PersonaGender? gender,
    String? languageCode,
    VoidCallback? onDone,
  }) async {
    if (text.trim().isEmpty) return false;

    final id = ++_utterance;
    await _stopInternal();
    if (id != _utterance) return false;

    if (backend == 'system') {
      return _speakSystem(
        text,
        id: id,
        gender: gender,
        languageCode: languageCode,
        onDone: onDone,
      );
    }

    if (!await ensureReady(backend: backend, model: model)) return false;
    if (id != _utterance) return false;
    return _speakOnDevice(text, id: id, languageCode: languageCode, onDone: onDone);
  }

  /// Menghentikan playback dan membatalkan sintesis yang masih berjalan.
  Future<void> stop() async {
    _utterance++;
    await _stopInternal();
  }

  // ── Backend: system (flutter_tts) ───────────────────────────────────────

  Future<bool> _initSystemTts() async {
    if (_systemTtsInitialized) return true;
    _flutterTts.setStartHandler(() {});
    _flutterTts.setCompletionHandler(() {
      if (_activeSystemId != _utterance) return;
      final cb = _onComplete;
      _onComplete = null;
      cb?.call();
    });
    _flutterTts.setCancelHandler(() {
      if (_activeSystemId != _utterance) return;
      _onComplete = null;
    });
    _flutterTts.setErrorHandler((_) {
      if (_activeSystemId != _utterance) return;
      _onComplete = null;
    });
    _systemTtsInitialized = true;
    return true;
  }
  Future<bool> _speakSystem(
    String text, {
    required int id,
    PersonaGender? gender,
    String? languageCode,
    VoidCallback? onDone,
  }) async {
    try {
      await _initSystemTts();
      await _flutterTts.stop();
      if (id != _utterance) return false;

      _onComplete = onDone;
      _activeSystemId = id;

      await _flutterTts.setLanguage(languageCode ?? 'id-ID');
      if (id != _utterance) return false;
      if (gender == PersonaGender.girlfriend) {
        await _flutterTts.setPitch(1.6);
        await _flutterTts.setSpeechRate(0.4);
      } else {
        await _flutterTts.setPitch(0.88);
        await _flutterTts.setSpeechRate(0.47);
      }
      if (id != _utterance) return false;

      await _flutterTts.speak(text);
      return true;
    } catch (e) {
      AppLogger.debug('System TTS failed', e);
      _finish(id);
      return false;
    }
  }

  // ── Backend: on-device (flutter_edge_ai_speech) ─────────────────────────

  Future<bool> _speakOnDevice(
    String text, {
    required int id,
    String? languageCode,
    VoidCallback? onDone,
  }) async {
    if (id != _utterance) return false;
    _onComplete = onDone;

    try {
      final synth = await FlutterEdgeAi.getActiveTts(language: languageCode);
      if (id != _utterance) return false;

      final pcm = await synth.synthesize(text);
      if (id != _utterance) return false;
      if (pcm.isEmpty) {
        _finish(id);
        return false;
      }

      await FlutterPcmSound.setup(sampleRate: synth.sampleRate, channelCount: 1);
      if (id != _utterance) {
        try {
          await FlutterPcmSound.release();
        } catch (_) {}
        return false;
      }

      await FlutterPcmSound.feed(PcmArrayInt16(bytes: pcm.buffer.asByteData()));
      if (id != _utterance) {
        try {
          await FlutterPcmSound.release();
        } catch (_) {}
        return false;
      }

      FlutterPcmSound.start();

      // Belum ada callback "playback selesai" dari plugin PCM: durasi audio
      // dihitung dari panjang PCM (catat sebagai known issue).
      final seconds = (pcm.length / 2 / synth.sampleRate).clamp(0.2, 120.0);
      _finishTimer?.cancel();
      _finishTimer = Timer(
        Duration(milliseconds: (seconds * 1000).round()),
        () => _finish(id),
      );
      return true;
    } catch (e) {
      AppLogger.debug('TTS playback failed', e);
      _finish(id);
      return false;
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────

  Future<void> _stopInternal() async {
    _finishTimer?.cancel();
    _finishTimer = null;
    _onComplete = null;
    try {
      await _flutterTts.stop();
    } catch (e) {
      AppLogger.debug('System TTS stop failed', e);
    }
    try {
      await FlutterPcmSound.release();
    } catch (e) {
      AppLogger.debug('PCM release failed', e);
    }
  }

  /// Memanggil callback selesai sekali, hanya untuk utterance yang masih aktif.
  void _finish(int id) {
    if (id != _utterance) return;
    _finishTimer?.cancel();
    _finishTimer = null;
    final cb = _onComplete;
    _onComplete = null;
    cb?.call();
  }
}
