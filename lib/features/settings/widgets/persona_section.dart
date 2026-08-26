// Settings — Persona section (ringkasan + edit + reset).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/confirm_dialog.dart';
import '../../../core/design/components/section_card.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../models/objectbox_provider.dart';
import '../../../models/persona_config.dart';
import '../../persona/avatar_catalog.dart';
import '../../persona/persona_controller.dart';
import '../../persona/persona_edit_sheet.dart';
import '../settings_controller.dart';

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
    );

    if (!confirmed || !context.mounted) return;
    HapticFeedback.heavyImpact();

    ref.read(personaProvider.notifier).reset();
    ref.read(objectBoxServiceProvider).memoryFactBox.removeAll();
    ref.read(objectBoxServiceProvider).moodStateBox.removeAll();

    final updated = settings.copyWith(isPersonaSetup: false);
    ref.read(appSettingsProvider.notifier).save(updated);
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
                  avatarCircle(opt, AppSizes.avatarMd),
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
              leading: const Icon(Icons.refresh_rounded, color: AppColors.heartRed),
              title: Text(strings.settingsResetPersona, style: const TextStyle(color: AppColors.heartRed)),
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
