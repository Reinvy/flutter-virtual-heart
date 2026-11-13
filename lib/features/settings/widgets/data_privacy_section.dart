// Settings — Data & Privasi (FR-19): hapus percakapan, ekspor chat, reset total.
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/design/components/app_icon_badge.dart';
import '../../../core/design/components/confirm_dialog.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../models/message.dart';
import 'package:virtual_heart/services/database/objectbox_provider.dart';
import '../../../services/ai/model_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/stt_service.dart';
import '../../../services/tts_service.dart';
import '../../chat/chat_controller.dart';
import '../../chat/chat_models.dart';
import '../../chat/mood_provider.dart';
import '../../memory/memory_controller.dart';
import '../../notifications/notification_controller.dart';
import 'package:virtual_heart/services/ai/model_ready_provider.dart';
import '../../persona/persona_controller.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'settings_row.dart';
import 'settings_section.dart';

class DataPrivacySection extends ConsumerWidget {
  const DataPrivacySection({super.key});

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.settingsDeleteConversationsTitle,
      body: strings.settingsDeleteConversationsBody,
      confirmLabel: strings.settingsDelete,
      cancelLabel: strings.commonCancel,
    );

    if (!confirmed || !context.mounted) return;
    HapticFeedback.heavyImpact();

    final container = ProviderScope.containerOf(context, listen: false);
    // Tunggu generasi & tulis post-process selesai sebelum tabel dikosongkan.
    await container.read(chatProvider.notifier).cancelGeneration();
    container.read(appSettingsProvider.notifier).deleteAllConversations();
    container.invalidate(chatProvider);
    container.invalidate(pendingChatDraftProvider);
    if (!context.mounted) return;
    _snack(context, strings.settingsDeletedSnack);
  }

  /// Reset total: semua data lokal dihapus, notifikasi dibatalkan, lalu kembali
  /// ke gerbang usia. File model tetap dipakai (tidak diunduh ulang).
  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.settingsResetAllTitle,
      body: strings.settingsResetAllBody,
      confirmLabel: strings.settingsResetAllConfirm,
      cancelLabel: strings.commonCancel,
    );

    if (!confirmed || !context.mounted) return;
    HapticFeedback.heavyImpact();

    final container = ProviderScope.containerOf(context, listen: false);
    // Hentikan pekerjaan yang masih menulis ke database & audio aktif.
    await container.read(chatProvider.notifier).cancelGeneration();
    await container.read(modelServiceProvider.notifier).cancelDownload();
    await TtsService().stop();
    await SttService().cancel();

    try {
      await container.read(notificationServiceProvider).cancelAll();
    } catch (_) {
      // Notifikasi opsional: hapus data tetap dilanjutkan.
    }
    container.read(notificationServiceProvider).clearPendingTap();
    await container.read(appSettingsProvider.notifier).resetAllData();

    container.invalidate(chatProvider);
    container.invalidate(pendingChatDraftProvider);
    container.invalidate(memoryFactsProvider);
    container.invalidate(personaProvider);
    container.invalidate(moodProvider);
    container.invalidate(modelServiceProvider);
    container.invalidate(modelReadyProvider);
    container.invalidate(notificationProvider);

    if (!context.mounted) return;
    _snack(context, strings.settingsResetAllDone);
    context.go(AppRoutes.ageGate);
  }

  Future<void> _exportChat(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final db = ref.read(objectBoxServiceProvider);
    final messages = db.messageBox.getAll()..sort(compareMessages);
    if (messages.isEmpty) {
      if (context.mounted) _snack(context, strings.settingsExportEmptySnack);
      return;
    }

    final persona = ref.read(personaProvider);
    final personaName = (persona?.name.isNotEmpty == true)
        ? persona!.name
        : strings.settingsExportAiFallback;
    final userNickname = (persona?.nicknameForUser.isNotEmpty == true)
        ? persona!.nicknameForUser
        : strings.settingsExportUserFallback;

    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final fmtShort = DateFormat('dd/MM HH:mm');
    final buffer = StringBuffer()
      ..writeln(strings.settingsExportTitle)
      ..writeln(strings.settingsExportDate(fmt.format(DateTime.now())))
      ..writeln(strings.settingsExportPersona(personaName))
      ..writeln('=' * 40)
      ..writeln();

    for (final msg in messages) {
      final sender = msg.role == MessageRole.user ? userNickname : personaName;
      buffer
        ..writeln('[${fmtShort.format(msg.timestamp)}] $sender:')
        ..writeln(msg.content)
        ..writeln();
    }

    final fileName =
        'virtualheart_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));

    try {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/plain',
        dialogTitle: strings.settingsExportChat,
      );
      if (!context.mounted) return;
      _snack(
        context,
        uri == null ? strings.settingsExportCancelled : strings.settingsExportSaved,
      );
    } on UnimplementedError {
      await _exportToAppDocuments(context, strings, buffer.toString(), fileName);
    } catch (_) {
      if (context.mounted) _snack(context, strings.settingsExportFailed);
    }
  }

  /// Fallback platform tanpa dialog simpan: tulis ke dokumen aplikasi dan
  /// tampilkan path lengkapnya agar pengguna tahu di mana file berada.
  Future<void> _exportToAppDocuments(
    BuildContext context,
    AppStrings strings,
    String content,
    String fileName,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content, flush: true);
      if (!context.mounted) return;
      _snack(
        context,
        strings.settingsExportSuccess.replaceAll('{file}', file.path),
        duration: const Duration(seconds: 6),
      );
    } catch (_) {
      if (context.mounted) _snack(context, strings.settingsExportFailed);
    }
  }

  static void _snack(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration ?? const Duration(seconds: 4)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    return SettingsSection(
      title: strings.settingsDataPrivacy,
      icon: Icons.lock_outline_rounded,
      children: [
        Container(
          margin: const EdgeInsets.all(AppSizes.spaceMd),
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSizes.radiusControl),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIconBadge(icon: Icons.shield_outlined),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.settingsLocalStorage,
                      style: AppTextStyles.settingsLabel(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceXxs),
                    Text(
                      strings.settingsLocalStorageBody,
                      style: AppTextStyles.bodySmall(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SettingsRow(
          icon: Icons.privacy_tip_outlined,
          title: strings.settingsPrivacyPolicy,
          showChevron: true,
          onTap: () => context.push(AppRoutes.privacy),
        ),
        SettingsRow(
          icon: Icons.download_rounded,
          title: strings.settingsExportChat,
          subtitle: strings.settingsExportChatDesc,
          showChevron: true,
          onTap: () => _exportChat(context, ref),
        ),
        SettingsRow(
          icon: Icons.delete_outline_rounded,
          title: strings.settingsDeleteConversations,
          destructive: true,
          onTap: () => _confirmDeleteAll(context, ref),
        ),
        SettingsRow(
          icon: Icons.warning_amber_rounded,
          title: strings.settingsResetAll,
          subtitle: strings.settingsResetAllDesc,
          destructive: true,
          onTap: () => _confirmResetAll(context, ref),
        ),
      ],
    );
  }
}
