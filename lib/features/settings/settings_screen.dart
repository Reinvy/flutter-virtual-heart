// Fitur Settings (FR-18) — tab pengaturan utama.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'widgets/appearance_section.dart';
import 'widgets/data_privacy_section.dart';
import 'widgets/language_section.dart';
import 'widgets/model_section.dart';
import 'widgets/notifications_section.dart';
import 'widgets/persona_section.dart';
import 'widgets/voice_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      body: AppContent(
        maxWidth: AppSizes.contentMaxWidth,
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSizes.spaceSm,
            bottom: AppSizes.spaceXl,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceLg),
              child: Text(
                strings.settingsTitle,
                style: AppTextStyles.displaySmall(
                  context,
                  color: scheme.onSurface,
                ),
              ),
            ),
            PersonaSection(settings: settings),
            const SizedBox(height: AppSizes.spaceLg),
            AppearanceSection(settings: settings),
            const SizedBox(height: AppSizes.spaceLg),
            LanguageSection(settings: settings),
            const SizedBox(height: AppSizes.spaceLg),
            ModelSection(settings: settings),
            const SizedBox(height: AppSizes.spaceLg),
            VoiceSection(settings: settings),
            const SizedBox(height: AppSizes.spaceLg),
            NotificationsSection(settings: settings),
            const SizedBox(height: AppSizes.spaceLg),
            const DataPrivacySection(),
          ],
        ),
      ),
    );
  }
}
