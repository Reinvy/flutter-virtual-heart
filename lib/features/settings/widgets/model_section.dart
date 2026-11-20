// Settings §Model (FR-04) — mode aktif (Lokal / Cloud BYOK), parameter cloud, & ganti provider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../models/ai_provider_profile.dart';
import '../../../models/app_settings.dart';
import '../../../services/ai/ai_provider_controller.dart';
import '../../../services/ai/model_catalog.dart';
import '../../model/cloud_provider_editor_sheet.dart';
import 'settings_row.dart';
import 'settings_section.dart';

/// Label model aktif: nama profil & model cloud saat mode Cloud BYOK,
/// atau nama katalog/file saat mode Lokal.
String currentModelLabel(
  AppSettings settings,
  AppStrings strings, {
  AiProviderProfile? cloudProfile,
}) {
  if (settings.aiMode == AiMode.cloud) {
    if (cloudProfile != null && cloudProfile.modelId.isNotEmpty) {
      return '${cloudProfile.name} · ${cloudProfile.modelId}';
    }
    return strings.modelNotInstalled;
  }
  if (settings.modelVariant.isEmpty) return strings.modelNotInstalled;
  for (final option in kModelOptions) {
    if (option.fileName == settings.modelVariant) return option.name;
  }
  return settings.modelVariant;
}

class ModelSection extends ConsumerWidget {
  const ModelSection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final cloudProfile = settings.aiMode == AiMode.cloud
        ? ref.watch(activeCloudProfileProvider)
        : null;
    final modeTag = settings.aiMode == AiMode.cloud
        ? strings.aiModeCloud
        : strings.aiModeLocal;

    return SettingsSection(
      title: strings.settingsModel,
      icon: settings.aiMode == AiMode.cloud
          ? Icons.cloud_outlined
          : Icons.memory_rounded,
      children: [
        SettingsRow(
          icon: settings.aiMode == AiMode.cloud
              ? Icons.cloud_done_outlined
              : Icons.smart_toy_outlined,
          title: '${strings.modelCurrent} ($modeTag)',
          subtitle: currentModelLabel(
            settings,
            strings,
            cloudProfile: cloudProfile,
          ),
        ),
        if (settings.aiMode == AiMode.cloud && cloudProfile != null)
          SettingsRow(
            icon: Icons.tune_rounded,
            title: strings.settingsCloudParameters,
            subtitle: _paramSummary(cloudProfile),
            showChevron: true,
            onTap: () => showCloudProviderEditorSheet(
              context,
              initialProfile: cloudProfile,
              isNew: false,
            ),
          ),
        SettingsRow(
          icon: Icons.swap_horiz_rounded,
          title: strings.modelChange,
          showChevron: true,
          onTap: () => context.push(AppRoutes.modelDownload),
        ),
      ],
    );
  }

  static String _paramSummary(AiProviderProfile p) {
    final temp = p.temperature != null
        ? 'Temp ${p.temperature!.toStringAsFixed(1)}'
        : 'Temp Auto';
    return '$temp · ${p.maxOutputTokens} tok · ${p.maxHistoryMessages} msg';
  }
}
