import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/app_settings.dart';
import '../../../providers/app_settings_provider.dart';
import 'section_widgets.dart';

class LanguageSection extends ConsumerWidget {
  final AppSettings settings;
  const LanguageSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, 'Bahasa AI', Icons.translate_rounded),
        sectionCard(
          context: context,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bahasa yang digunakan AI saat membalas',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SegmentedButton<AppLanguage>(
                    segments: const [
                      ButtonSegment(value: AppLanguage.indonesian, label: Text('Indonesia')),
                      ButtonSegment(value: AppLanguage.english, label: Text('English')),
                      ButtonSegment(value: AppLanguage.mixed, label: Text('Campur')),
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
