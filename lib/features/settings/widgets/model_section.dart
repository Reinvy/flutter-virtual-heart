// Settings §Model (FR-04) — model aktif + tombol ganti model.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../models/app_settings.dart';
import '../../../services/ai/model_catalog.dart';
import 'settings_row.dart';
import 'settings_section.dart';

/// Label model aktif: nama katalog bila dikenal, selain itu nama file.
String currentModelLabel(AppSettings settings, AppStrings strings) {
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
    return SettingsSection(
      title: strings.settingsModel,
      icon: Icons.memory_rounded,
      children: [
        SettingsRow(
          icon: Icons.smart_toy_outlined,
          title: strings.modelCurrent,
          subtitle: currentModelLabel(settings, strings),
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
}
