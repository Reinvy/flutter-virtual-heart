// Fitur Notifications (FR-16) — observer lifecycle aplikasi.
//
// Menjadwalkan notifikasi check-in saat app di-background, membatalkan saat
// kembali, dan memperbarui mood idle (FR-09) saat app dibuka.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_logger.dart';
import '../../services/mood_service.dart';
import '../chat/mood_provider.dart';
import 'notification_controller.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  AppLifecycleObserver(this._ref);

  /// `WidgetRef` diterima — punya `.read` yang sama dengan `Ref`.
  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // App ke background — jadwalkan check-in (jika diaktifkan).
        _ref.read(notificationProvider.notifier).handleCheckin(schedule: true);
      case AppLifecycleState.resumed:
        // Kembali — batalkan check-in & perbarui mood dari waktu idle.
        _ref.read(notificationProvider.notifier).handleCheckin(schedule: false);
        _updateMoodFromIdle();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _updateMoodFromIdle() {
    try {
      _ref.read(moodServiceProvider).updateMoodFromIdleTime();
      _ref.read(moodProvider.notifier).refresh();
    } catch (e) {
      AppLogger.debug('Idle mood update skipped', e);
    }
  }
}
