// Settings — Persona section (ringkasan + edit + reset).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/app_sheet.dart';
import '../../../core/design/components/confirm_dialog.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../../../models/persona_config.dart';
import '../../../services/stt_service.dart';
import '../../../services/tts_service.dart';
import '../../chat/chat_controller.dart';
import '../../chat/mood_provider.dart';
import '../../memory/memory_controller.dart';
import '../../notifications/notification_controller.dart';
import '../../persona/avatar_catalog.dart';
import '../../persona/persona_controller.dart';
import '../../persona/persona_edit_sheet.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'settings_row.dart';
import 'settings_section.dart';

class PersonaSection extends ConsumerWidget {
  final AppSettings settings;
  const PersonaSection({super.key, required this.settings});

  Future<void> _showEditSheet(BuildContext context) async {
    await showAppSheet<void>(context, child: const PersonaEditSheet());
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

    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(chatProvider.notifier).cancelGeneration();
    await TtsService().stop();
    await SttService().cancel();

    await container.read(appSettingsProvider.notifier).resetPersonaData();
    container.invalidate(chatProvider);
    container.invalidate(pendingChatDraftProvider);
    container.invalidate(memoryFactsProvider);
    container.invalidate(moodProvider);
    container.invalidate(personaProvider);

    try {
      await container
          .read(notificationProvider.notifier)
          .applySettings(container.read(appSettingsProvider));
    } catch (_) {
      // Notifikasi opsional: abaikan kegagalan sinkronisasi.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final persona = ref.watch(personaProvider);
    final opt = avatarOptForId(persona?.avatarId);

    return SettingsSection(
      title: strings.settingsPersona,
      icon: Icons.favorite_outline_rounded,
      children: [
        Container(
          color: scheme.surfaceContainerLow,
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Row(
            children: [
              avatarCircle(context, opt, AppSizes.avatarCard),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona?.name.isNotEmpty == true
                          ? persona!.name
                          : strings.personaCreateTitle,
                      style: AppTextStyles.headingLarge(
                        context,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (persona != null) ...[
                      const SizedBox(height: AppSizes.spaceXxs),
                      Text(
                        _genderLabel(strings, persona.gender),
                        style: AppTextStyles.bodySmall(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (persona?.nicknameForUser.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        fillPlaceholders(strings.personaCallsYou, {
                          'nickname': persona!.nicknameForUser,
                        }),
                        style: AppTextStyles.bodySmall(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SettingsRow(
          icon: Icons.edit_outlined,
          title: strings.settingsEditPersona,
          showChevron: true,
          onTap: () => _showEditSheet(context),
        ),
        SettingsRow(
          icon: Icons.refresh_rounded,
          title: strings.settingsResetPersona,
          destructive: true,
          onTap: () => _confirmReset(context, ref),
        ),
      ],
    );
  }

  static String _genderLabel(AppStrings strings, PersonaGender gender) {
    return gender == PersonaGender.girlfriend
        ? strings.personaGenderGirlfriend
        : strings.personaGenderBoyfriend;
  }
}
