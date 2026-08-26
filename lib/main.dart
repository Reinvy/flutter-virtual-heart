// Entry point — init AI engine & database, lalu jalankan app.
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'models/objectbox_provider.dart';
import 'services/database/objectbox_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the MediaPipe (.task) inference engine. flutter_gemma core ships no
  // engine; the engine package must be passed here or inference will throw.
  await FlutterGemma.initialize(
    inferenceEngines: const [MediaPipeEngine()],
  );

  final objectBoxService = await ObjectBoxService.create();

  runApp(
    ProviderScope(
      overrides: [objectBoxServiceProvider.overrideWithValue(objectBoxService)],
      child: const VirtualHeartApp(),
    ),
  );
}
