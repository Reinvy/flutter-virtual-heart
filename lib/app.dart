// Root widget — MaterialApp, Riverpod, GoRouter, lifecycle observer,
// dan routing tap notifikasi.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/app_theme.dart';
import 'core/design/app_theme_provider.dart';
import 'core/errors/app_logger.dart';
import 'core/router/app_router.dart';
import 'package:virtual_heart/services/ai/model_ready_provider.dart';
import 'features/notifications/app_lifecycle_observer.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
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
  String? _deferredTapPayload;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    final notifications = NotificationService();
    _tapSubscription = notifications.taps.listen(_handleNotificationTap);

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
  /// Pada cold start saat model masih dimuat, payload disimpan sampai siap.
  void _handleNotificationTap(String? payload) {
    if (payload != kNotificationPayloadChat || !mounted) return;

    final settings = ref.read(appSettingsProvider);
    final setupDone =
        settings.isAgeVerified &&
        settings.isOnboardingDone &&
        settings.isPersonaSetup;
    if (!setupDone) {
      _deferredTapPayload = null;
      AppLogger.debug('Notification tap ignored: setup incomplete');
      return;
    }

    if (!ref.read(modelReadyProvider)) {
      _deferredTapPayload = payload;
      AppLogger.debug('Notification tap deferred until model is ready');
      return;
    }

    _deferredTapPayload = null;
    ref.read(routerProvider).go(AppRoutes.chat);
  }

  void _flushDeferredNotificationTap() {
    final pending = _deferredTapPayload;
    if (pending == null) return;
    _handleNotificationTap(pending);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(modelReadyProvider, (_, next) {
      if (next) _flushDeferredNotificationTap();
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeStyle = ref.watch(themeStyleProvider);
    final language = ref.watch(appSettingsProvider.select((s) => s.language));

    return MaterialApp.router(
      title: 'VirtualHeart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightFor(themeStyle),
      darkTheme: AppTheme.darkFor(themeStyle),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('id'), Locale('en')],
      locale: language == AppLanguage.english
          ? const Locale('en')
          : const Locale('id'),
    );
  }
}
