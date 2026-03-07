import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/app_settings_provider.dart';
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
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: AppSizes.iconMd),
          onPressed: () => context.pop(),
        ),
        title: Text('Pengaturan', style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
        children: [
          PersonaSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          AppearanceSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          LanguageSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          VoiceSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          NotificationsSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          const DataPrivacySection(),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}
