import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/models/persona_config.dart';

/// Singleton wrapper around [FlutterTts].
///
/// Adjusts language and pitch based on persona [gender].
/// The caller is responsible for checking [AppSettings.ttsEnabled] before
/// invoking [speak].
class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  VoidCallback? _onComplete;

  bool get isSpeaking => _isSpeaking;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb && Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ], IosTextToSpeechAudioMode.defaultMode);
    }

    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _onComplete?.call();
      _onComplete = null;
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      _onComplete = null;
    });
    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      _onComplete = null;
    });
  }

  /// Speaks [text] using a voice appropriate for [gender].
  ///
  /// Stops any ongoing speech beforehand.
  /// [onDone] is called when speech completes naturally.
  Future<void> speak(
    String text, {
    PersonaGender gender = PersonaGender.girlfriend,
    VoidCallback? onDone,
  }) async {
    await _ensureInitialized();
    await _tts.stop();

    _onComplete = onDone;

    // Prefer Indonesian; fall back to English if unavailable.
    await _tts.setLanguage('en-US');

    // Tune pitch/rate per gender for a more natural voice.
    if (gender == PersonaGender.girlfriend) {
      await _tts.setPitch(1.6);
      await _tts.setSpeechRate(0.4);
    } else {
      await _tts.setPitch(0.88);
      await _tts.setSpeechRate(0.47);
    }

    await _tts.speak(text);
  }

  /// Stops any ongoing speech immediately.
  Future<void> stop() async {
    _onComplete = null;
    await _tts.stop();
    _isSpeaking = false;
  }
}
