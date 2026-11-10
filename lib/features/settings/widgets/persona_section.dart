// Settings — Persona section (ringkasan + edit + reset).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/confirm_dialog.dart';
import '../../../core/design/components/section_card.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../models/persona_config.dart';
import '../../chat/chat_controller.dart';
import '../../chat/mood_provider.dart';
import '../../memory/memory_controller.dart';
import '../../notifications/notification_controller.dart';
import '../../persona/avatar_catalog.dart';
import '../../persona/persona_controller.dart';
import '../../persona/persona_edit_sheet.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';

class PersonaSection extends ConsumerWidget {
  final AppSettings settings;
  const PersonaSection({super.key, required this.settings});

  Future<void> _showEditSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PersonaEditSheet(),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.settingsResetPersonaTitle,
      body: strings.settingsResetPersonaBody,
      confirmLabel: strings.settingsDelete,
      cancelLabel: strings.commonCancel,
    );

    if (!confirmed || !context.mounted) return;
    HapticFeedback.heavyImpact();

    // Hentikan generasi yang sedang berjalan sebelum data dihapus.
    await ref.read(chatProvider.notifier).cancelGeneration();
    if (!context.mounted) return;

    await ref.read(appSettingsProvider.notifier).resetPersonaData();
    ref.invalidate(chatProvider);
    ref.invalidate(memoryFactsProvider);
    ref.invalidate(moodProvider);
    ref.invalidate(personaProvider);

    // Nama persona lama harus hilang dari jadwal notifikasi.
    try {
      await ref
          .read(notificationProvider.notifier)
          .applySettings(ref.read(appSettingsProvider));
    } catch (_) {
      // Notifikasi opsional: abaikan kegagalan sinkronisasi.
    }
    // Router guard akan redirect ke /persona-setup otomatis.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final subtleColor = scheme.onSurfaceVariant;
    final persona = ref.watch(personaProvider);

    final isGirlfriend = persona?.gender == PersonaGender.girlfriend;
    final opt = avatarOptFor(persona?.avatarId, isGirlfriend: isGirlfriend);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, strings.settingsPersona, Icons.favorite_rounded),
        sectionCard(
          context: context,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.spaceMd),
              child: Row(
                children: [
                  avatarCircle(context, opt, AppSizes.avatarMd),
                  const SizedBox(width: AppSizes.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona?.name.isNotEmpty == true ? persona!.name : strings.personaCreateTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (persona != null) ...[
                          const SizedBox(height: AppSizes.spaceXxs),
                          Text(
                            _genderLabel(strings, persona.gender),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtleColor),
                          ),
                        ],
                        if (persona?.nicknameForUser.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            fillPlaceholders(strings.personaCallsYou, {
                              'nickname': persona!.nicknameForUser,
                            }),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: subtleColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: Text(strings.settingsEditPersona),
              trailing: Icon(Icons.chevron_right_rounded, color: subtleColor),
              onTap: () => _showEditSheet(context),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.refresh_rounded, color: scheme.error),
              title: Text(strings.settingsResetPersona, style: TextStyle(color: scheme.error)),
              onTap: () => _confirmReset(context, ref),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }

  static String _genderLabel(AppStrings strings, PersonaGender gender) {
    return gender == PersonaGender.girlfriend
        ? strings.personaGenderGirlfriend
        : strings.personaGenderBoyfriend;
  }
}
