// Settings — Bahasa AI (FR-20).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/section_card.dart';
import '../../../core/design/tokens/app_colors.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../settings_controller.dart';

class LanguageSection extends ConsumerWidget {
  final AppSettings settings;
  const LanguageSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, strings.settingsLanguage, Icons.translate_rounded),
        sectionCard(
          context: context,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.settingsAiLanguageDesc,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtleColor),
                  ),
                  const SizedBox(height: AppSizes.spaceXs),
                  SegmentedButton<AppLanguage>(
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
                      if (s.isNotEmpty) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(appSettingsProvider.notifier)
                            .save(settings.copyWith(language: s.first));
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 120.ms).slideY(begin: 0.04, end: 0);
  }
}
