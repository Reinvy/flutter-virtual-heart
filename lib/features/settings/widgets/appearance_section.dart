// Settings — Appearance (tema, default light).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/section_card.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import '../settings_controller.dart';

class AppearanceSection extends ConsumerWidget {
  final AppSettings settings;
  const AppearanceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, strings.settingsAppearance, Icons.palette_outlined),
        sectionCard(
          context: context,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.settingsTheme, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppSizes.spaceXs),
                  SegmentedButton<AppThemeSetting>(
                    segments: [
                      ButtonSegment(
                        value: AppThemeSetting.light,
                        label: Text(strings.settingsThemeLight),
                        icon: const Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: AppThemeSetting.dark,
                        label: Text(strings.settingsThemeDark),
                        icon: const Icon(Icons.dark_mode_rounded),
                      ),
                      ButtonSegment(
                        value: AppThemeSetting.system,
                        label: Text(strings.settingsThemeSystem),
                        icon: const Icon(Icons.phone_android_rounded),
                      ),
                    ],
                    selected: {settings.theme},
                    onSelectionChanged: (s) {
                      if (s.isNotEmpty) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(appSettingsProvider.notifier)
                            .save(settings.copyWith(theme: s.first));
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 60.ms).slideY(begin: 0.04, end: 0);
  }
}
