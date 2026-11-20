import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:genkit/genkit.dart' as gk;
import 'package:path_provider/path_provider.dart';

import '../core/errors/app_logger.dart';
import '../models/ai_provider_profile.dart';
import '../models/cloud_speech_config.dart';
import '../models/persona_config.dart';
import 'ai/genkit/genkit_cloud_client.dart';
import 'ai/speech_model_catalog.dart';

/// Facade Text-to-Speech dengan lima backend:
///
/// - **system** (`flutter_tts`): suara OS, tanpa unduhan model.
/// - **gemma** (`flutter_edge_ai_speech`): sintesis on-device → PCM 16-bit → [FlutterPcmSound].
/// - **elevenlabs** / **openai** / **google**: sintesis Cloud BYOK melalui
///   [GenkitCloudClient] → audio MP3/WAV → [AudioPlayer] (`audioplayers`) dengan
///   callback selesai playback (`onPlayerComplete`) yang akurat.
///
/// Setiap utterance diberi nomor urut. `stop()` menaikkan nomor tersebut dan
/// membatalkan request jaringan cloud yang masih berjalan sehingga tidak pernah
/// ada playback yang bertumpuk.
class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  static const Set<String> cloudBackends = {'elevenlabs', 'openai', 'google'};
  static bool isCloudBackend(String backend) => cloudBackends.contains(backend);

  final FlutterTts _flutterTts = FlutterTts();
  AudioPlayer? _audioPlayer;
  StreamSubscription<void>? _playerCompleteSub;
  String? _tempAudioPath;

  /// Model on-device yang sudah terpasang & aktif (null bila belum).
  String? _readyModel;
  VoidCallback? _onComplete;
  Timer? _finishTimer;
  gk.CancellationController? _activeCloudCancel;
  int _utterance = 0;
  int _activeSystemId = 0;
  int _activeCloudAudioId = 0;
  bool _systemTtsInitialized = false;
  Future<bool>? _ensuringFuture;
  String? _ensuringModel;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Memastikan backend siap.
  ///
  /// - `system`: init `flutter_tts`.
  /// - `gemma`: unduh model [model] bila belum terpasang.
  /// - `elevenlabs` / `openai` / `google`: verifikasi kredensial API key.
  Future<bool> ensureReady({
    String backend = 'system',
    String model = 'inflect',
    CloudSpeechConfig? cloudConfig,
    String? apiKey,
    void Function(int percent)? onProgress,
  }) async {
    if (backend == 'system') {
      return _initSystemTts();
    }
    if (isCloudBackend(backend)) {
      return _isCloudReady(
        backend: backend,
        cloudConfig: cloudConfig,
        apiKey: apiKey,
      );
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

  bool _isCloudReady({
    required String backend,
    CloudSpeechConfig? cloudConfig,
    String? apiKey,
  }) {
    final key = (apiKey ?? '').trim();
    if (key.isNotEmpty) return true;
    if (backend == 'openai' &&
        AiProviderProfile.isLocalNetworkUrl(cloudConfig?.openaiTtsBaseUrl ?? '')) {
      return true;
    }
    return false;
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
  bool isModelActive(String model) =>
      _readyModel == model && FlutterEdgeAi.hasActiveTts();

  /// Menyintesis [text] dan memutarnya sesuai [backend] & [gender].
  Future<bool> speak(
    String text, {
    String backend = 'system',
    String model = 'inflect',
    PersonaGender? gender,
    String? languageCode,
    CloudSpeechConfig? cloudConfig,
    String? apiKey,
    GenkitCloudClient? cloudClient,
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

    if (isCloudBackend(backend)) {
      return _speakCloud(
        text,
        id: id,
        backend: backend,
        cloudConfig: cloudConfig ?? CloudSpeechConfig(),
        apiKey: apiKey ?? '',
        cloudClient: cloudClient ?? const GenkitCloudClient(),
        gender: gender,
        languageCode: languageCode,
        onDone: onDone,
      );
    }

    if (!await ensureReady(backend: backend, model: model)) return false;
    if (id != _utterance) return false;
    return _speakOnDevice(
      text,
      id: id,
      languageCode: languageCode,
      onDone: onDone,
    );
  }

  /// Menghentikan playback dan membatalkan sintesis yang masih berjalan.
  Future<void> stop() async {
    _utterance++;
    await _stopInternal();
  }

  // ── Backend: cloud (Genkit + audioplayers) ──────────────────────────────

  AudioPlayer _ensureAudioPlayer() {
    final existing = _audioPlayer;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _playerCompleteSub = player.onPlayerComplete.listen((_) {
      final activeId = _activeCloudAudioId;
      if (activeId == _utterance) {
        unawaited(_deleteTempAudio());
        _finish(activeId);
      }
    });
    _audioPlayer = player;
    return player;
  }

  Future<bool> _speakCloud(
    String text, {
    required int id,
    required String backend,
    required CloudSpeechConfig cloudConfig,
    required String apiKey,
    required GenkitCloudClient cloudClient,
    PersonaGender? gender,
    String? languageCode,
    VoidCallback? onDone,
  }) async {
    if (!_isCloudReady(
      backend: backend,
      cloudConfig: cloudConfig,
      apiKey: apiKey,
    )) {
      return false;
    }

    final cancelCtrl = gk.CancellationController();
    _activeCloudCancel = cancelCtrl;
    _onComplete = onDone;

    try {
      final audio = await cloudClient.synthesizeSpeech(
        backend: backend,
        config: cloudConfig,
        apiKey: apiKey,
        text: text,
        languageCode: languageCode,
        gender: gender,
        cancellation: cancelCtrl,
      );
      if (id != _utterance) return false;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/vh_tts_${DateTime.now().microsecondsSinceEpoch}.${audio.fileExtension}';
      final file = File(path);
      await file.writeAsBytes(audio.bytes, flush: true);
      if (id != _utterance) {
        await _deleteFileQuietly(path);
        return false;
      }

      await _deleteTempAudio();
      _tempAudioPath = path;
      _activeCloudAudioId = id;

      final player = _ensureAudioPlayer();
      await player.stop();
      if (id != _utterance) {
        await _deleteTempAudio();
        return false;
      }
      await player.play(DeviceFileSource(path));
      return true;
    } on gk.CancelledException {
      return false;
    } catch (e) {
      AppLogger.debug('Cloud TTS playback failed ($backend)', e);
      await _deleteTempAudio();
      _finish(id);
      return false;
    } finally {
      if (identical(_activeCloudCancel, cancelCtrl)) {
        _activeCloudCancel = null;
      }
    }
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
    final cloudCancel = _activeCloudCancel;
    _activeCloudCancel = null;
    if (cloudCancel != null && !cloudCancel.isCancelled) {
      cloudCancel.cancel('TTS stopped');
    }
    try {
      await _audioPlayer?.stop();
    } catch (e) {
      AppLogger.debug('Cloud audio stop failed', e);
    }
    await _deleteTempAudio();
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

  Future<void> _deleteTempAudio() async {
    final path = _tempAudioPath;
    _tempAudioPath = null;
    if (path != null) await _deleteFileQuietly(path);
  }

  static Future<void> _deleteFileQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.debug('Temp TTS audio cleanup failed', e);
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

  @visibleForTesting
  Future<void> disposePlayerForTest() async {
    await _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    await _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}
