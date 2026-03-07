import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Singleton wrapper around [SpeechToText].
///
/// Usage:
///   1. [initialize()] on first use (called lazily by [startListening]).
///   2. Subscribe to the [Stream<String>] from [startListening] for partial
///      transcriptions.
///   3. Stream closes automatically on final result or session timeout.
///   4. Call [stopListening] to end a session early.
class SttService {
  SttService._internal();
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _isListening = false;
  StreamController<String>? _activeController;

  bool get isListening => _isListening;
  bool get isAvailable => _initialized;

  /// Initialises the STT engine and requests microphone permission.
  ///
  /// Returns `true` on success, `false` if the device doesn't support STT or
  /// the user denies the permission.
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) {
        _isListening = false;
        _closeController();
      },
      onStatus: (status) {
        if (status == stt.SpeechToText.notListeningStatus ||
            status == stt.SpeechToText.doneStatus) {
          _isListening = false;
          _closeController();
        }
      },
    );
    return _initialized;
  }

  /// Starts a new listening session.
  ///
  /// Returns a [Stream<String>] of partial transcriptions. The stream closes
  /// automatically on a final result or timeout. Call [stopListening] to end
  /// the session early.
  Stream<String> startListening({String localeId = 'id_ID'}) {
    _closeController(); // cancel any previous session
    _activeController = StreamController<String>();
    _beginListening(localeId);
    return _activeController!.stream;
  }

  Future<void> _beginListening(String localeId) async {
    final ok = await initialize();
    if (!ok) {
      _addError('Speech recognition tidak tersedia di perangkat ini');
      return;
    }

    if (_speech.isListening) await _speech.stop();

    _isListening = true;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (_activeController == null || _activeController!.isClosed) return;
        if (result.recognizedWords.isNotEmpty) {
          _activeController!.add(result.recognizedWords);
        }
        if (result.finalResult) {
          _isListening = false;
          _closeController();
        }
      },
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Ends the current session and flushes the last partial result.
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
    _closeController();
  }

  /// Cancels the current session without emitting a result.
  Future<void> cancel() async {
    _isListening = false;
    await _speech.cancel();
    _closeController();
  }

  void _closeController() {
    if (_activeController != null && !_activeController!.isClosed) {
      _activeController!.close();
    }
    _activeController = null;
  }

  void _addError(String message) {
    if (_activeController != null && !_activeController!.isClosed) {
      _activeController!.addError(Exception(message));
      _activeController!.close();
    }
    _activeController = null;
  }
}
