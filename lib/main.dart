import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database/objectbox_service.dart';
import 'providers/objectbox_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  final objectBoxService = await ObjectBoxService.create();

  runApp(
    ProviderScope(
      overrides: [objectBoxServiceProvider.overrideWithValue(objectBoxService)],
      child: const VirtualHeartApp(),
    ),
  );
}
