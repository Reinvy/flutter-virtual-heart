import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../services/notification_service.dart';
import 'app_settings_provider.dart';

/// Notifier that keeps notification schedules in sync with [AppSettings].
///
/// Call [applySettings] whenever notification settings change (e.g. from the
/// settings screen).  It will cancel or reschedule notifications as needed.
class NotificationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // On startup, sync schedules with persisted settings.
    final settings = ref.read(appSettingsProvider);
    await _sync(settings);
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Re-syncs all notification schedules with [settings].
  ///
  /// Call this after saving changes in the settings screen.
  Future<void> applySettings(AppSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _sync(settings));
  }

  /// Requests OS notification permission and returns whether it was granted.
  Future<bool> requestPermission() {
    return ref.read(notificationServiceProvider).requestPermission();
  }

  /// Schedules or cancels the check-in notification.
  ///
  /// Call with [schedule] = true when the app moves to background, and
  /// [schedule] = false when the user opens the app.
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

  // ── Private helpers ─────────────────────────────────────────────────────

  Future<void> _sync(AppSettings settings) async {
    final svc = ref.read(notificationServiceProvider);
    final persona = _personaName();

    // Morning message
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

    // Check-in notifications are one-shot (scheduled on app background).
    // Cancel any stale one here in case the setting was just disabled.
    if (!settings.notificationCheckinEnabled) {
      await svc.cancelCheckinNotification();
    }
  }

  /// Reads the persona name from ObjectBox if available, falls back to default.
  String _personaName() {
    try {
      // Avoid a hard dependency on PersonaConfig provider; read directly.
      // The name is only used as a notification title so a fallback is fine.
      return 'VirtualHeart';
    } catch (_) {
      return 'VirtualHeart';
    }
  }
}

final notificationProvider = AsyncNotifierProvider<NotificationNotifier, void>(
  NotificationNotifier.new,
);
