// Fitur Settings (FR-18) — layar pengaturan utama.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import 'settings_controller.dart';
import 'widgets/appearance_section.dart';
import 'widgets/data_privacy_section.dart';
import 'widgets/language_section.dart';
import 'widgets/notifications_section.dart';
import 'widgets/persona_section.dart';
import 'widgets/voice_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: AppSizes.iconMd),
          onPressed: () => context.pop(),
        ),
        title: Text(strings.settingsTitle, style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceXs),
        children: [
          PersonaSection(settings: settings),
          const SizedBox(height: AppSizes.spaceMd),
          AppearanceSection(settings: settings),
          const SizedBox(height: AppSizes.spaceMd),
          LanguageSection(settings: settings),
          const SizedBox(height: AppSizes.spaceMd),
          VoiceSection(settings: settings),
          const SizedBox(height: AppSizes.spaceMd),
          NotificationsSection(settings: settings),
          const SizedBox(height: AppSizes.spaceMd),
          const DataPrivacySection(),
          const SizedBox(height: AppSizes.spaceXl),
        ],
      ),
    );
  }
}
