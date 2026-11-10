// Fitur Chat (FR-09) — indikator mood di app bar (docs/DESIGN.md §3.4).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/mood_visuals.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../mood_provider.dart';

/// Subtitle AppBar chat: pill berisi emoji + label mood persona.
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
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
