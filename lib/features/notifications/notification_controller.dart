// Fitur Notifications (FR-15..FR-17) — controller sinkronisasi jadwal.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_logger.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/app_settings.dart';
import '../../services/notification_service.dart';
import '../persona/persona_controller.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

/// Menjaga jadwal notifikasi tetap sinkron dengan [AppSettings].
///
/// Semua mutasi jadwal masuk antrean: dua `applySettings` yang berdekatan
/// tidak boleh saling menimpa (mis. persona disimpan lalu sakelar diubah).
class NotificationNotifier extends AsyncNotifier<void> {
  Future<void> _queue = Future.value();

  @override
  Future<void> build() async {
    final settings = ref.read(appSettingsProvider);
    await _enqueue(() => _sync(settings));
  }

  /// Menyinkronkan ulang semua jadwal notifikasi dengan [settings].
  Future<void> applySettings(AppSettings settings) async {
    state = const AsyncLoading();
    try {
      await _enqueue(() => _sync(settings));
      if (ref.mounted) state = const AsyncData(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
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
    await _enqueue(() async {
      if (!ref.mounted) return;
      final settings = ref.read(appSettingsProvider);
      final svc = ref.read(notificationServiceProvider);

      if (!schedule || !settings.notificationCheckinEnabled) {
        await svc.cancelCheckinNotification();
        return;
      }

      if (!await svc.hasPermission()) {
        await svc.cancelCheckinNotification();
        return;
      }

      final strings = ref.read(appStringsProvider);
      await svc.scheduleCheckinNotification(
        hoursFromNow: settings.notificationCheckinHours,
        personaName: _personaName(),
        messages: strings.checkinMessages,
      );
    });
  }

  // ── Private ─────────────────────────────────────────────────────────────

  /// Menjalankan [op] setelah operasi sebelumnya selesai (berhasil/gagal).
  Future<T> _enqueue<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _sync(AppSettings settings) async {
    if (!ref.mounted) return;
    final svc = ref.read(notificationServiceProvider);
    final strings = ref.read(appStringsProvider);
    final persona = _personaName();

    if (settings.notificationMorningEnabled) {
      if (!await svc.hasPermission()) {
        await svc.cancelMorningMessage();
        return;
      }
      final parts = settings.notificationMorningTime.split(':');
      final hour = int.tryParse(parts.first) ?? 7;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      await svc.scheduleMorningMessage(
        TimeOfDay(hour: hour, minute: minute),
        personaName: persona,
        messages: strings.morningMessages,
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
