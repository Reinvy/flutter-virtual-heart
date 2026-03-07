import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// ── Notification channel IDs ──────────────────────────────────────────────

const _kMorningChannelId = 'vh_morning';
const _kCheckinChannelId = 'vh_checkin';
const _kSpecialDayChannelId = 'vh_special';

// ── Notification IDs ─────────────────────────────────────────────────────

const _kMorningNotifId = 1;
const _kCheckinNotifId = 2;
const _kSpecialDayBaseId = 100; // incremented per scheduled special day

// ── Romantic message templates (PRD Appendix A) ──────────────────────────

const _morningMessages = [
  'Selamat pagi, Sayang 🌸 Aku sudah mimpi tentang kamu tadi malam.',
  'Good morning! Hari ini pasti jadi hari yang indah karena ada kamu 💖',
  'Kamu yang pertama aku pikirkan pagi ini. Selamat pagi~ 🌅',
  'Bangun sudah? Aku nunggu kabarmu dari tadi. Selamat pagi, Sayang 💕',
  'Pagi ini terasa lebih hangat karena aku ingat kamu. Selamat pagi! ☀️',
];

const _checkinMessages = [
  'Hei, kamu di mana? Udah lama aku nunggu kabarmu 🥺',
  'Kangen deh... boleh cerita harimu sebentar? ❤️',
  'Aku kepo gimana harimu hari ini. Cerita yuk? 💝',
  'Lagi sibuk ya? Aku di sini nunggu kamu, lho~ 🌷',
  'Semoga harimu baik-baik saja. Aku selalu di sini kalau kamu mau cerita 💫',
];

/// Manages all locally-scheduled notifications for VirtualHeart.
///
/// Must call [initialize] once at app start (e.g., inside `main.dart` or
/// `AppInitializationWrapper`) before using any other method.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final _rng = Random();

  bool _initialized = false;

  // ── Initialization ────────────────────────────────────────────────────

  /// Initializes the plugin, timezone database, and requests OS permission.
  ///
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;

    // Load timezone database.
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we request explicitly below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // ── Permission ───────────────────────────────────────────────────────

  /// Requests notification permission from the OS.
  ///
  /// Returns `true` if permission was granted, `false` otherwise.
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }

    return false;
  }

  // ── FR-18: Morning Message ────────────────────────────────────────────

  /// Schedules (or re-schedules) a daily morning notification at [time].
  ///
  /// A random romantic greeting is selected from [_morningMessages].
  /// [personaName] is used as the notification title.
  Future<void> scheduleMorningMessage(TimeOfDay time, {String personaName = 'VirtualHeart'}) async {
    await _ensureInitialized();

    final body = _morningMessages[_rng.nextInt(_morningMessages.length)];
    final scheduledDate = _nextInstanceOf(time);

    await _plugin.zonedSchedule(
      _kMorningNotifId,
      personaName,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kMorningChannelId,
          'Pesan Pagi',
          channelDescription: 'Sapaan pagi romantis dari pasangan virtualmu.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  /// Cancels the morning message notification.
  Future<void> cancelMorningMessage() async {
    await _plugin.cancel(_kMorningNotifId);
  }

  // ── FR-19: Check-in Notification ──────────────────────────────────────

  /// Schedules a one-time check-in notification [hoursFromNow] hours from now.
  ///
  /// The caller (e.g., `AppLifecycleObserver`) is responsible for calling this
  /// when the app goes to background and cancelling it when the user returns.
  /// Default interval: 6 hours (per PRD FR-19).
  Future<void> scheduleCheckinNotification({
    int hoursFromNow = 6,
    String personaName = 'VirtualHeart',
  }) async {
    await _ensureInitialized();

    final body = _checkinMessages[_rng.nextInt(_checkinMessages.length)];
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(hours: hoursFromNow));

    await _plugin.zonedSchedule(
      _kCheckinNotifId,
      personaName,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kCheckinChannelId,
          'Check-in',
          channelDescription: 'Pengingat dari pasangan virtualmu.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels any pending check-in notification (call when user opens the app).
  Future<void> cancelCheckinNotification() async {
    await _plugin.cancel(_kCheckinNotifId);
  }

  // ── FR-20: Special Day Notification ──────────────────────────────────

  /// Schedules a one-time notification on [date] for a special occasion.
  ///
  /// [message] should be pre-formed (e.g., "Selamat ulang tahun, Sayang! 🎂").
  /// Each call uses a unique ID derived from [_kSpecialDayBaseId] + [slotIndex]
  /// so multiple special days can coexist.
  Future<void> scheduleSpecialDay(
    DateTime date,
    String message, {
    String personaName = 'VirtualHeart',
    int slotIndex = 0,
  }) async {
    await _ensureInitialized();

    final scheduledDate = tz.TZDateTime.from(date, tz.local);

    // Only schedule if the date is in the future.
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _kSpecialDayBaseId + slotIndex,
      personaName,
      message,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kSpecialDayChannelId,
          'Hari Spesial',
          channelDescription: 'Notifikasi untuk momen yang berarti.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a special day notification at [slotIndex].
  Future<void> cancelSpecialDay({int slotIndex = 0}) async {
    await _plugin.cancel(_kSpecialDayBaseId + slotIndex);
  }

  // ── Utilities ─────────────────────────────────────────────────────────

  /// Cancels ALL pending notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Returns all pending notification requests (useful for debugging/settings).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  /// Returns the next [TZDateTime] matching [time] (today or tomorrow).
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((_) {
  return NotificationService();
});
