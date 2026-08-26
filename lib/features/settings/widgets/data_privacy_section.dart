// Settings — Data & Privasi (FR-19): hapus percakapan & ekspor chat.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/design/components/confirm_dialog.dart';
import '../../../core/design/components/section_card.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/message.dart';
import '../../../models/objectbox_provider.dart';
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
    );

    if (!confirmed || !context.mounted) return;
    HapticFeedback.heavyImpact();
    ref.read(appSettingsProvider.notifier).deleteAllConversations();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.settingsDeletedSnack)));
    }
  }

  Future<void> _exportChat(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final db = ref.read(objectBoxServiceProvider);
    final messages = db.messageBox.getAll()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (messages.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.settingsExportEmptySnack)));
      }
      return;
    }

    final persona = ref.read(personaProvider);
    final personaName = (persona?.name.isNotEmpty == true) ? persona!.name : 'AI';
    final userNickname = (persona?.nicknameForUser.isNotEmpty == true)
        ? persona!.nicknameForUser
        : 'You';

    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final fmtShort = DateFormat('dd/MM HH:mm');
    final buffer = StringBuffer()
      ..writeln('VirtualHeart — Chat Export')
      ..writeln('Export date: ${fmt.format(DateTime.now())}')
      ..writeln('Persona: $personaName')
      ..writeln('=' * 40)
      ..writeln();

    for (final msg in messages) {
      final sender = msg.role == MessageRole.user ? userNickname : personaName;
      buffer
        ..writeln('[${fmtShort.format(msg.timestamp)}] $sender:')
        ..writeln(msg.content)
        ..writeln();
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'virtualheart_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString(), flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.settingsExportSuccess.replaceAll('{file}', fileName)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.settingsExportFailed)));
      }
    }
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
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.04, end: 0);
  }
}
