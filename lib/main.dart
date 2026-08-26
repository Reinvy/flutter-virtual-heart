// Entry point — init AI engine & database, lalu jalankan app.
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_gemma_speech/flutter_gemma_speech.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'models/objectbox_provider.dart';
import 'services/database/objectbox_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Token HuggingFace opsional (untuk model gated) — dari SharedPreferences.
  final prefs = await SharedPreferences.getInstance();
  final hfToken = prefs.getString('hf_token');
  final effectiveToken = (hfToken == null || hfToken.isEmpty) ? null : hfToken;

  // Register inference engines (MediaPipe .task + LiteRT-LM .litertlm) dan
  // backend speech on-device (STT + TTS via LiteRT C API).
  await FlutterGemma.initialize(
    inferenceEngines: const [MediaPipeEngine(), LiteRtLmEngine()],
    sttBackends: const [LiteRtSttBackend()],
    ttsBackends: const [LiteRtTtsBackend()],
    huggingFaceToken: effectiveToken,
    maxDownloadRetries: 10,
  );

  final objectBoxService = await ObjectBoxService.create();

  runApp(
    ProviderScope(
      overrides: [objectBoxServiceProvider.overrideWithValue(objectBoxService)],
      child: const VirtualHeartApp(),
    ),
  );
}
