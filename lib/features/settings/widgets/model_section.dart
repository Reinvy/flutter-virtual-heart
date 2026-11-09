// Settings §Model (FR-04) — model aktif + tombol ganti model.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/section_card.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../models/app_settings.dart';
import '../../../services/ai/model_catalog.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, strings.settingsModel, Icons.memory_rounded),
        sectionCard(
          context: context,
          children: [
            ListTile(
              leading: Icon(Icons.smart_toy_outlined, color: scheme.primary),
              title: Text(strings.modelCurrent),
              subtitle: Text(currentModelLabel(settings, strings)),
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz_rounded, color: scheme.primary),
              title: Text(strings.modelChange),
              trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
              onTap: () => context.push(AppRoutes.modelDownload),
            ),
          ],
        ),
      ],
    );
  }
}
