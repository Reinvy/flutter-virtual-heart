// Fitur Notifications (FR-15..FR-17) — controller sinkronisasi jadwal.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_logger.dart';
import '../../models/app_settings.dart';
import '../../services/notification_service.dart';
import '../persona/persona_controller.dart';
import '../settings/settings_controller.dart';

/// Menjaga jadwal notifikasi tetap sinkron dengan [AppSettings].
class NotificationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    final settings = ref.read(appSettingsProvider);
    await _sync(settings);
  }

  /// Menyinkronkan ulang semua jadwal notifikasi dengan [settings].
  Future<void> applySettings(AppSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _sync(settings));
  }

  /// Meminta izin notifikasi OS.
  Future<bool> requestPermission() {
    return ref.read(notificationServiceProvider).requestPermission();
  }

  /// Menjadwalkan/membatalkan notifikasi check-in (FR-16).
  ///
  /// Panggil dengan [schedule] = true saat app masuk background, dan false saat
  /// app dibuka kembali.
  Future<void> handleCheckin({required bool schedule}) async {
    final settings = ref.read(appSettingsProvider);
    final svc = ref.read(notificationServiceProvider);

    if (schedule && settings.notificationCheckinEnabled) {
      final persona = _personaName();
      await svc.scheduleCheckinNotification(personaName: persona);
    } else {
      await svc.cancelCheckinNotification();
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────

  Future<void> _sync(AppSettings settings) async {
    final svc = ref.read(notificationServiceProvider);
    final persona = _personaName();

    if (settings.notificationMorningEnabled) {
      final parts = settings.notificationMorningTime.split(':');
      final hour = int.tryParse(parts.first) ?? 7;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      await svc.scheduleMorningMessage(
        TimeOfDay(hour: hour, minute: minute),
        personaName: persona,
      );
    } else {
      await svc.cancelMorningMessage();
    }

    if (!settings.notificationCheckinEnabled) {
      await svc.cancelCheckinNotification();
    }
  }

  /// Nama persona asli dari ObjectBox (fallback nama app).
  String _personaName() {
    try {
      final persona = ref.read(personaProvider);
      return (persona?.name.isNotEmpty ?? false) ? persona!.name : 'VirtualHeart';
    } catch (e) {
      AppLogger.debug('Persona name fallback', e);
      return 'VirtualHeart';
    }
  }
}

final notificationProvider = AsyncNotifierProvider<NotificationNotifier, void>(
  NotificationNotifier.new,
);
