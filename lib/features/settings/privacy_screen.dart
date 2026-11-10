// Fitur Settings — Kebijakan Privasi (FR-19).
//
// Teks kebijakan berasal dari AppStrings agar tetap terlokalisasi dan tidak
// di-hardcode di widget. Isinya harus selaras dengan docs/PRIVACY.md.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.ageGate),
        ),
        title: Text(strings.privacyTitle),
      ),
      body: AppContent(
        maxWidth: 680,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spaceLg),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
              boxShadow: AppShadows.card(context),
            ),
            child: SelectableText(
              strings.privacyPolicy,
              style: AppTextStyles.bodyLarge(
                color: scheme.onSurface,
              ).copyWith(height: 1.7),
            ),
          ),
        ),
      ),
    );
  }
}
