// Settings — Bahasa AI (FR-20).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'settings_section.dart';

class LanguageSection extends ConsumerWidget {
  final AppSettings settings;
  const LanguageSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: strings.settingsLanguage,
      icon: Icons.translate_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.settingsAiLanguageDesc,
                style: AppTextStyles.bodyMedium(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<AppLanguage>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: AppLanguage.indonesian,
                      label: Text(strings.settingsLanguageIndonesian),
                    ),
                    ButtonSegment(
                      value: AppLanguage.english,
                      label: Text(strings.settingsLanguageEnglish),
                    ),
                    ButtonSegment(
                      value: AppLanguage.mixed,
                      label: Text(strings.settingsLanguageMixed),
                    ),
                  ],
                  selected: {settings.language},
                  onSelectionChanged: (s) {
                    if (s.isEmpty) return;
                    HapticFeedback.selectionClick();
                    ref
                        .read(appSettingsProvider.notifier)
                        .save(settings.copyWith(language: s.first));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
