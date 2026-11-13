// Fitur Chat (FR-09) — indikator mood minimalis hairline (docs/DESIGN.md §3.4).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/mood_visuals.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../mood_provider.dart';

/// Pill hairline berisi emoji + label mood persona.
class MoodIndicator extends ConsumerWidget {
  const MoodIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final mood = ref.watch(moodProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(moodEmoji(mood.current), style: const TextStyle(fontSize: 12)),
          const SizedBox(width: AppSizes.spaceXxs),
          Flexible(
            child: Text(
              moodLabel(strings, mood.current),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.moodIndicator(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
