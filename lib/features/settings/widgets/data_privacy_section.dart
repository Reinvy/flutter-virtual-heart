// Settings — Data & Privasi (FR-19): hapus percakapan, ekspor chat, reset total.
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/design/components/confirm_dialog.dart';
import '../../../core/design/components/section_card.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../models/message.dart';
import '../../../models/objectbox_provider.dart';
import '../../../services/ai/model_service.dart';
import '../../../services/notification_service.dart';
import '../../chat/chat_controller.dart';
import '../../chat/mood_provider.dart';
import '../../memory/memory_controller.dart';
import '../../model/model_ready_provider.dart';
import '../../persona/persona_controller.dart';
import '../settings_controller.dart';

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

    // Tunggu generasi & tulis post-process selesai sebelum tabel dikosongkan.
    await ref.read(chatProvider.notifier).cancelGeneration();
    if (!context.mounted) return;

    ref.read(appSettingsProvider.notifier).deleteAllConversations();
    ref.invalidate(chatProvider);
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

    // Hentikan pekerjaan yang masih menulis ke database.
    await ref.read(chatProvider.notifier).cancelGeneration();
    await ref.read(modelServiceProvider.notifier).cancelDownload();
    if (!context.mounted) return;

    try {
      await ref.read(notificationServiceProvider).cancelAll();
    } catch (_) {
      // Notifikasi opsional: hapus data tetap dilanjutkan.
    }
    await ref.read(appSettingsProvider.notifier).resetAllData();

    ref.invalidate(chatProvider);
    ref.invalidate(memoryFactsProvider);
    ref.invalidate(personaProvider);
    ref.invalidate(moodProvider);
    ref.invalidate(modelServiceProvider);
    ref.invalidate(modelReadyProvider);

    if (!context.mounted) return;
    _snack(context, strings.settingsResetAllDone);
    context.go(AppRoutes.ageGate);
  }

  Future<void> _exportChat(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final db = ref.read(objectBoxServiceProvider);
    final messages = db.messageBox.getAll()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
    final subtleColor = scheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, strings.settingsDataPrivacy, Icons.lock_outline_rounded),
        sectionCard(
          context: context,
          children: [
            ListTile(
              dense: true,
              leading: Icon(Icons.storage_rounded, color: subtleColor),
              title: Text(strings.settingsLocalStorage),
              subtitle: Text(strings.settingsLocalStorageBody),
              isThreeLine: true,
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.privacy_tip_outlined, color: subtleColor),
              title: Text(strings.settingsPrivacyPolicy),
              trailing: Icon(Icons.chevron_right_rounded, color: subtleColor),
              onTap: () => context.push(AppRoutes.privacy),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
              title: Text(strings.settingsDeleteConversations, style: TextStyle(color: scheme.error)),
              onTap: () => _confirmDeleteAll(context, ref),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.download_rounded, color: scheme.primary),
              title: Text(strings.settingsExportChat),
              subtitle: Text(strings.settingsExportChatDesc),
              trailing: Icon(Icons.chevron_right_rounded, color: subtleColor),
              onTap: () => _exportChat(context, ref),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.warning_amber_rounded, color: scheme.error),
              title: Text(
                strings.settingsResetAll,
                style: TextStyle(color: scheme.error),
              ),
              subtitle: Text(strings.settingsResetAllDesc),
              isThreeLine: true,
              onTap: () => _confirmResetAll(context, ref),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.04, end: 0);
  }
}
