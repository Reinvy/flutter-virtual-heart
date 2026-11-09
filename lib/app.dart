// Root widget — MaterialApp, Riverpod, GoRouter, lifecycle observer,
// dan routing tap notifikasi.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/app_theme.dart';
import 'core/design/app_theme_provider.dart';
import 'core/errors/app_logger.dart';
import 'core/router/app_router.dart';
import 'features/model/model_ready_provider.dart';
import 'features/notifications/app_lifecycle_observer.dart';
import 'features/settings/settings_controller.dart';
import 'models/app_settings.dart';
import 'services/notification_service.dart';

class VirtualHeartApp extends ConsumerStatefulWidget {
  const VirtualHeartApp({super.key});

  @override
  ConsumerState<VirtualHeartApp> createState() => _VirtualHeartAppState();
}

class _VirtualHeartAppState extends ConsumerState<VirtualHeartApp> {
  AppLifecycleObserver? _lifecycleObserver;
  StreamSubscription<String?>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    // `ref` di initState adalah WidgetRef; observer menerimanya sebagai Ref.
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    final notifications = NotificationService();
    _tapSubscription = notifications.taps.listen(_handleNotificationTap);

    // Cold start dari notifikasi: router belum tentu siap di frame pertama.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationTap(notifications.takePendingTap());
    });
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    }
    super.dispose();
  }

  /// Navigasi ke chat hanya bila seluruh gate sudah terlewati & model siap.
  void _handleNotificationTap(String? payload) {
    if (payload != kNotificationPayloadChat || !mounted) return;

    final settings = ref.read(appSettingsProvider);
    final ready = settings.isAgeVerified &&
        settings.isOnboardingDone &&
        settings.isPersonaSetup &&
        ref.read(modelReadyProvider);

    if (!ready) {
      AppLogger.debug('Notification tap ignored: setup/model not ready');
      return;
    }

    ref.read(routerProvider).go(AppRoutes.chat);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(appSettingsProvider).language;

    return MaterialApp.router(
      title: 'VirtualHeart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('id'), Locale('en')],
      locale: language == AppLanguage.english ? const Locale('en') : const Locale('id'),
    );
  }
}
