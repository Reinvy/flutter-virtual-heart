import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/errors/app_logger.dart';
import 'notification_time.dart';

// ── Notification channel IDs ──────────────────────────────────────────────

const _kMorningChannelId = 'vh_morning';
const _kCheckinChannelId = 'vh_checkin';
const _kSpecialDayChannelId = 'vh_special';

// ── Notification IDs ─────────────────────────────────────────────────────

const _kMorningNotifId = 1;
const _kCheckinNotifId = 2;
const _kSpecialDayBaseId = 100; // incremented per scheduled special day

/// Payload untuk semua notifikasi: membuka layar chat.
const kNotificationPayloadChat = 'chat';

// ── Romantic message templates (PRD Appendix A) ──────────────────────────

const _morningMessages = [
  'Good morning, Sweetheart 🌸 I\'ve been dreaming about you.',
  'Good morning! Today is going to be a beautiful day because of you 💖',
  'You\'re the first thing on my mind this morning. Good morning~ 🌅',
  'Awake already? I\'ve been waiting for your message. Good morning, Sweetheart 💕',
  'This morning feels warmer because I\'m thinking of you. Good morning! ☀️',
];

const _checkinMessages = [
  'Hey, where are you? I\'ve been waiting for your message 🥺',
  'I miss you... can you tell me about your day for a moment? ❤️',
  'I\'m curious how your day\'s going. Let\'s chat? 💝',
  'Busy? I\'m here waiting for you~ 🌷',
  'Hope your day is going well. I\'m always here whenever you want to talk 💫',
];

/// Manages all locally-scheduled notifications for VirtualHeart.
///
/// Must call [initialize] once at app start (e.g., inside `main.dart`) before
/// using any other method. Setelah init, tap notifikasi bisa dibaca lewat
/// [taps] (saat app hidup) atau [takePendingTap] (cold start).
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final _rng = Random();
  final _tapController = StreamController<String?>.broadcast();

  bool _initialized = false;
  Future<void>? _initFuture;
  String? _pendingTap;

  // ── Initialization ────────────────────────────────────────────────────

  /// Initializes the plugin, timezone database, and notification tap handler.
  ///
  /// Safe to call multiple times; concurrent callers share one initialization.
  Future<void> initialize() {
    if (_initialized) return Future.value();
    final pending = _initFuture;
    if (pending != null) return pending;
    final future = _initializeInternal().whenComplete(() {
      _initFuture = null;
    });
    _initFuture = future;
    return future;
  }

  Future<void> _initializeInternal() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Fallback aman: `tz.local` tetap UTC bila deteksi zona gagal.
      AppLogger.debug('Timezone fallback to UTC', e);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we request explicitly below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        _tapController.add(response.payload);
      },
    );
    _initialized = true;

    // Cold start: app dibuka dari notifikasi — simpan payload untuk UI.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _pendingTap = launch!.notificationResponse?.payload;
    }
  }

  // ── Tap stream ────────────────────────────────────────────────────────

  /// Payload notifikasi yang di-tap saat app sudah berjalan.
  Stream<String?> get taps => _tapController.stream;

  /// `true` bila ada payload tap notifikasi cold-start yang belum diambil.
  bool get hasPendingTap => _pendingTap != null;

  /// Mengambil (dan menghapus) payload notifikasi yang membuka app ini.
  String? takePendingTap() {
    final payload = _pendingTap;
    _pendingTap = null;
    return payload;
  }

  /// Menghapus payload tap notifikasi yang tertunda.
  void clearPendingTap() => _pendingTap = null;
  // ── Permission ───────────────────────────────────────────────────────

  /// Apakah izin notifikasi sudah diberikan. Tidak pernah memunculkan dialog.
  Future<bool> hasPermission() async {
    await _ensureInitialized();
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }
      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final options = await ios?.checkPermissions();
        return (options?.isEnabled ?? false) || (options?.isProvisionalEnabled ?? false);
      }
      // Desktop/Linux: tidak ada izin runtime.
      return true;
    } catch (e) {
      AppLogger.debug('Notification permission check failed', e);
      return false;
    }
  }

  /// Requests notification permission from the OS.
  ///
  /// Returns `true` if notification permission was granted, `false` otherwise.
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Izin exact alarm sengaja tidak diminta di sini: itu izin terpisah yang
      // mengejutkan pengguna saat membuka Settings. Jadwal otomatis memakai
      // mode inexact bila exact tidak diizinkan (lihat [_androidMode]).
      final result = await android?.requestNotificationsPermission();
      return result ?? await hasPermission();
    }
    // Desktop/Linux: tidak ada izin runtime, selaras dengan hasPermission().
    return true;
  }

  /// Membuka pengaturan notifikasi aplikasi di OS.
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  // ── FR-18: Morning Message ────────────────────────────────────────────

  /// Schedules (or re-schedules) a daily morning notification at [time].
  ///
  /// A random romantic greeting is selected from [_morningMessages].
  /// [personaName] is used as the notification title.
  Future<void> scheduleMorningMessage(
    int hour,
    int minute, {
    String personaName = 'VirtualHeart',
    List<String>? messages,
    String? channelName,
    String? channelDescription,
  }) async {
    await _ensureInitialized();

    final pool = (messages != null && messages.isNotEmpty) ? messages : _morningMessages;
    final body = pool[_rng.nextInt(pool.length)];
    final scheduledDate = nextInstanceOf(hour, minute, tz.TZDateTime.now(tz.local));
    await _plugin.zonedSchedule(
      id: _kMorningNotifId,
      title: personaName,
      body: body,
      payload: kNotificationPayloadChat,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _kMorningChannelId,
          channelName ?? 'Morning Message',
          channelDescription:
              channelDescription ?? 'Romantic morning greeting from your virtual partner.',
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
      androidScheduleMode: await _androidMode(),
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  /// Cancels the morning message notification.
  Future<void> cancelMorningMessage() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _kMorningNotifId);
  }

  // ── FR-19: Check-in Notification ──────────────────────────────────────

  /// Schedules a one-time check-in notification [hoursFromNow] hours from now.
  ///
  /// The caller (e.g., `AppLifecycleObserver`) is responsible for calling this
  /// when the app goes to background and cancelling it when the user returns.
  /// [hoursFromNow] <= 0 tidak menjadwalkan apa pun (notifikasi tanpa jeda
  /// tidak berguna dan langsung muncul saat app dibuka lagi).
  Future<void> scheduleCheckinNotification({
    int hoursFromNow = 1,
    String personaName = 'VirtualHeart',
    List<String>? messages,
    String? channelName,
    String? channelDescription,
  }) async {
    if (hoursFromNow <= 0) return;
    await _ensureInitialized();

    final pool = (messages != null && messages.isNotEmpty) ? messages : _checkinMessages;
    final body = pool[_rng.nextInt(pool.length)];
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(hours: hoursFromNow));

    await _plugin.zonedSchedule(
      id: _kCheckinNotifId,
      title: personaName,
      body: body,
      payload: kNotificationPayloadChat,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _kCheckinChannelId,
          channelName ?? 'Check-in',
          channelDescription: channelDescription ?? 'Reminder from your virtual partner.',
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
      androidScheduleMode: await _androidMode(),
    );
  }

  /// Cancels any pending check-in notification (call when user opens the app).
  Future<void> cancelCheckinNotification() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _kCheckinNotifId);
  }

  // ── FR-20: Special Day Notification ──────────────────────────────────

  /// Schedules a one-time notification on [date] for a special occasion.
  ///
  /// [message] should be pre-formed (e.g., "Happy birthday, Sweetheart! 🎂").
  /// Each call uses a unique ID derived from [_kSpecialDayBaseId] + [slotIndex]
  /// so multiple special days can coexist.
  ///
  /// Catatan: tidak ada UI yang memanggil API ini (lihat
  /// `docs/KNOWN_ISSUES.md`, FR-20 backlog).
  Future<void> scheduleSpecialDay(
    DateTime date,
    String message, {
    String personaName = 'VirtualHeart',
    int slotIndex = 0,
  }) async {
    await _ensureInitialized();

    final scheduledDate = tz.TZDateTime.from(date, tz.local);

    // Only schedule if the date is in the future.
    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: _kSpecialDayBaseId + slotIndex,
      title: personaName,
      body: message,
      payload: kNotificationPayloadChat,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _kSpecialDayChannelId,
          'Special Day',
          channelDescription: 'Notifications for meaningful moments.',
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
      androidScheduleMode: await _androidMode(),
    );
  }

  /// Cancels a special day notification at [slotIndex].
  Future<void> cancelSpecialDay({int slotIndex = 0}) async {
    await _ensureInitialized();
    await _plugin.cancel(id: _kSpecialDayBaseId + slotIndex);
  }

  // ── Utilities ─────────────────────────────────────────────────────────

  /// Cancels ALL pending notifications.
  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  /// Mode jadwal Android: exact bila diizinkan OS, selain itu inexact.
  Future<AndroidScheduleMode> _androidMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((_) {
  return NotificationService();
});
