// Fitur Notifications (FR-16) — observer lifecycle aplikasi.
//
// Menjadwalkan notifikasi check-in saat app benar-benar di-background
// (`paused`), membatalkannya saat app kembali, dan memperbarui mood idle
// (FR-09) saat app dibuka.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
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
      case AppLifecycleState.paused:
        // App masuk background (bukan sekadar kehilangan fokus): jadwalkan
        // check-in 1 jam ke depan bila fitur diaktifkan.
        unawaited(_handleCheckin(schedule: true));
      case AppLifecycleState.resumed:
        // Kembali — batalkan check-in & perbarui mood dari waktu idle.
        unawaited(_handleCheckin(schedule: false));
        _updateMoodFromIdle();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _handleCheckin({required bool schedule}) async {
    try {
      await _ref.read(notificationProvider.notifier).handleCheckin(schedule: schedule);
    } catch (e) {
      AppLogger.debug('Check-in notification skipped', e);
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
