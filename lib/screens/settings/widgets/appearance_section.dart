import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../data/models/app_settings.dart';
import '../../../providers/app_settings_provider.dart';
import 'section_widgets.dart';

class AppearanceSection extends ConsumerWidget {
  final AppSettings settings;
  const AppearanceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, 'Tampilan', Icons.palette_outlined),
        sectionCard(
          context: context,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppSizes.sm),
                  SegmentedButton<AppTheme>(
                    segments: const [
                      ButtonSegment(
                        value: AppTheme.dark,
                        label: Text('Gelap'),
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                      ButtonSegment(
                        value: AppTheme.light,
                        label: Text('Terang'),
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: AppTheme.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.phone_android_rounded),
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
