// Root widget — MaterialApp, Riverpod, GoRouter, lifecycle observer.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/app_theme.dart';
import 'core/design/app_theme_provider.dart';
import 'core/router/app_router.dart';
import 'features/notifications/app_lifecycle_observer.dart';

class VirtualHeartApp extends ConsumerStatefulWidget {
  const VirtualHeartApp({super.key});

  @override
  ConsumerState<VirtualHeartApp> createState() => _VirtualHeartAppState();
}

class _VirtualHeartAppState extends ConsumerState<VirtualHeartApp> {
  AppLifecycleObserver? _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    // `ref` di initState adalah WidgetRef; observer menerimanya sebagai Ref.
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);
  }

  @override
  void dispose() {
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'VirtualHeart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
