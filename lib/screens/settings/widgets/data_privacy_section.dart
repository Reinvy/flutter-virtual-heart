import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/message.dart';
import '../../../providers/objectbox_provider.dart';
import 'section_widgets.dart';

class DataPrivacySection extends ConsumerWidget {
  const DataPrivacySection({super.key});

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Conversations?'),
        content: const Text(
          'All chat history will be permanently deleted.\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.heartRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    HapticFeedback.heavyImpact();
    ref.read(objectBoxServiceProvider).messageBox.removeAll();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All conversations deleted')));
    }
  }

  Future<void> _exportChat(BuildContext context, WidgetRef ref) async {
    final db = ref.read(objectBoxServiceProvider);
    final messages = db.messageBox.getAll()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (messages.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No conversations to export')));
      }
      return;
    }

    final personas = db.personaBox.getAll();
    final persona = personas.isNotEmpty ? personas.first : null;
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
            content: Text('Chat exported to: $fileName'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to export chat')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, 'Data & Privacy', Icons.lock_outline_rounded),
        sectionCard(
          context: context,
          children: [
            ListTile(
              dense: true,
              leading: Icon(
                Icons.storage_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
              title: const Text('Local Storage'),
              subtitle: const Text(
                'All data is stored on this device.\n'
                'No data is ever sent to any server.',
              ),
              isThreeLine: true,
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.heartRed),
              title: const Text(
                'Delete All Conversations',
                style: TextStyle(color: AppColors.heartRed),
              ),
              onTap: () => _confirmDeleteAll(context, ref),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.download_rounded, color: AppColors.primary),
              title: const Text('Export Chat (.txt)'),
              subtitle: const Text('Save conversation history to a text file'),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
              onTap: () => _exportChat(context, ref),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.04, end: 0);
  }
}
