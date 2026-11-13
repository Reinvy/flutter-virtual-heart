// Entry point — init AI engine, notifikasi & database, lalu jalankan app.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';
import 'package:flutter_edge_ai_speech/flutter_edge_ai_speech.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'bootstrap_error_app.dart';
import 'core/errors/app_logger.dart';
import 'package:virtual_heart/services/database/objectbox_provider.dart';
import 'services/database/objectbox_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.error('Flutter framework error', details.exception, details.stack);
    if (kDebugMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Unhandled platform error', error, stack);
    return true;
  };
  try {
    // Token HuggingFace opsional (untuk model gated) — dari SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    final hfToken = prefs.getString('hf_token');
    final effectiveToken = (hfToken == null || hfToken.isEmpty) ? null : hfToken;

    // Register inference engines (MediaPipe .task + LiteRT-LM .litertlm) dan
    // backend speech on-device (STT + TTS via LiteRT C API).
    await FlutterEdgeAi.initialize(
      inferenceEngines: const [MediaPipeEngine(), LiteRtLmEngine()],
      sttBackends: const [LiteRtSttBackend()],
      ttsBackends: const [LiteRtTtsBackend()],
      huggingFaceToken: effectiveToken,
      maxDownloadRetries: 10,
    );

    // Notifikasi: init plugin + zona waktu lokal. Kegagalan di sini tidak boleh
    // menggagalkan start aplikasi (chat tetap bisa dipakai tanpa notifikasi).
    try {
      await NotificationService().initialize();
    } catch (e) {
      AppLogger.error('Notification init failed', e);
    }

    final objectBoxService = await ObjectBoxService.create();

    runApp(
      ProviderScope(
        overrides: [objectBoxServiceProvider.overrideWithValue(objectBoxService)],
        child: const VirtualHeartApp(),
      ),
    );
  } catch (e, st) {
    // Engine/database gagal dibuka sebelum UI pertama: tampilkan layar darurat
    // berbahasa ganda, bukan layar kosong.
    AppLogger.error('Bootstrap failed', e, st);
    runApp(const BootstrapErrorApp());
  }
}
