// Settings — Notifications (FR-15..FR-17 + status izin FR-18).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../services/notification_service.dart';
import '../../notifications/notification_controller.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'settings_permission_row.dart';
import 'settings_row.dart';
import 'settings_section.dart';

class NotificationsSection extends ConsumerWidget {
  final AppSettings settings;
  const NotificationsSection({super.key, required this.settings});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final parts = settings.notificationMorningTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 7,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: strings.settingsMorningTimeHelp,
    );

    if (picked == null || !context.mounted) return;

    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updated = settings.copyWith(notificationMorningTime: timeStr);
    await _apply(context, ref, updated);
  }

  /// Menyimpan perubahan lalu menyinkronkan jadwal; gagal → snackbar.
  Future<void> _apply(BuildContext context, WidgetRef ref, AppSettings updated) async {
    final strings = ref.read(appStringsProvider);
    try {
      ref.read(appSettingsProvider.notifier).save(updated);
      await ref.read(notificationProvider.notifier).applySettings(updated);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.settingsNotifPermissionDeniedSnack)),
      );
    }
  }

  /// Mengaktifkan pengingat hanya bila izin OS benar-benar ada.
  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required AppSettings Function() build,
    required bool enabled,
  }) async {
    final strings = ref.read(appStringsProvider);
    if (enabled) {
      final ok = await ref.read(notificationProvider.notifier).requestPermission();
      if (!ok) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.settingsNotifPermissionDeniedSnack)),
        );
        return;
      }
    }
    if (!context.mounted) return;
    await _apply(context, ref, build());
  }

  Future<void> _pickCheckinHours(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(strings.settingsCheckinHours),
        children: [
          for (final hours in AppSettings.checkinHourOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(hours),
              child: Text(strings.settingsCheckinHoursValue(hours)),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;

    final updated = settings.copyWith(notificationCheckinHours: selected);
    await _apply(context, ref, updated);
    await ref.read(notificationProvider.notifier).handleCheckin(schedule: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return SettingsSection(
      title: strings.settingsNotifications,
      icon: Icons.notifications_outlined,
      children: [
        SettingsRow(
          icon: Icons.wb_sunny_outlined,
          title: strings.settingsMorningMessage,
          subtitle: strings.settingsMorningMessageDesc,
          trailing: Switch.adaptive(
            value: settings.notificationMorningEnabled,
            onChanged: (v) async {
              HapticFeedback.selectionClick();
              await _toggle(
                context,
                ref,
                build: () => settings.copyWith(notificationMorningEnabled: v),
                enabled: v,
              );
            },
          ),
        ),
        if (settings.notificationMorningEnabled)
          SettingsRow(
            icon: Icons.access_time_rounded,
            title: strings.settingsMorningTime,
            onTap: () => _pickTime(context, ref),
            trailing: _ValueChevron(
              value: settings.notificationMorningTime,
            ),
          ),
        SettingsRow(
          icon: Icons.timer_outlined,
          title: strings.settingsCheckin,
          subtitle: strings.settingsCheckinDesc,
          trailing: Switch.adaptive(
            value: settings.notificationCheckinEnabled,
            onChanged: (v) async {
              HapticFeedback.selectionClick();
              await _toggle(
                context,
                ref,
                build: () => settings.copyWith(notificationCheckinEnabled: v),
                enabled: v,
              );
            },
          ),
        ),
        if (settings.notificationCheckinEnabled)
          SettingsRow(
            icon: Icons.hourglass_bottom_rounded,
            title: strings.settingsCheckinHours,
            onTap: () => _pickCheckinHours(context, ref),
            trailing: _ValueChevron(
              value: strings.settingsCheckinHoursValue(
                settings.notificationCheckinHours,
              ),
            ),
          ),
        _NotificationPermissionTile(strings: strings),
      ],
    );
  }
}

/// Nilai waktu dalam pill + chevron untuk baris yang membuka picker.
class _ValueChevron extends StatelessWidget {
  const _ValueChevron({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: AppSizes.spaceXxs,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            value,
            style: AppTextStyles.settingsLabel(
              color: AppColors.primaryDeepFor(context),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spaceXs),
        Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

/// Menampilkan status izin notifikasi (FR-18) secara jujur.
class _NotificationPermissionTile extends ConsumerStatefulWidget {
  const _NotificationPermissionTile({required this.strings});

  final AppStrings strings;

  @override
  ConsumerState<_NotificationPermissionTile> createState() =>
      _NotificationPermissionTileState();
}

class _NotificationPermissionTileState extends ConsumerState<_NotificationPermissionTile>
    with WidgetsBindingObserver {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  /// Hanya membaca status — tidak memunculkan dialog izin.
  Future<void> _load() async {
    final ok = await ref.read(notificationServiceProvider).hasPermission();
    if (mounted) setState(() => _granted = ok);
  }

  Future<void> _request() async {
    final ok = await ref.read(notificationProvider.notifier).requestPermission();
    if (!mounted) return;
    setState(() => _granted = ok);
    if (ok) {
      await ref
          .read(notificationProvider.notifier)
          .applySettings(ref.read(appSettingsProvider));
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final granted = _granted;

    if (granted == true) {
      return SettingsPermissionRow(
        icon: Icons.notifications_active_outlined,
        title: widget.strings.settingsNotifPermissionGranted,
        subtitle: '',
        state: SettingsPermissionState.granted,
      );
    }

    final undetermined = granted == null;
    return SettingsPermissionRow(
      icon: Icons.notifications_none_rounded,
      title: undetermined
          ? widget.strings.settingsNotifPermissionUndetermined
          : widget.strings.settingsNotifPermissionDenied,
      subtitle: widget.strings.settingsNotifPermissionOpenSettings,
      state: undetermined
          ? SettingsPermissionState.notRequested
          : SettingsPermissionState.denied,
      actionLabel: undetermined
          ? widget.strings.settingsNotifPermissionEnable
          : widget.strings.settingsNotifPermissionOpenSettings,
      onAction: undetermined ? _request : _openSettings,
    );
  }
}
