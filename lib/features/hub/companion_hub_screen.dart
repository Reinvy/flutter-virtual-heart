// Fitur Hub — beranda pendamping editorial (status, starter, snapshot memori & mesin).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/app_sheet.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/resonance_mark.dart';
import '../../core/design/components/secondary_button.dart';
import '../../core/design/components/section_card.dart';
import '../../core/design/mood_visuals.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_effects.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/persona_config.dart';
import '../../services/ai/model_ready_provider.dart';
import '../../services/settings/settings_service.dart';
import '../chat/chat_controller.dart';
import '../chat/mood_provider.dart';
import '../chat/widgets/mood_indicator.dart';
import '../memory/memory_controller.dart';
import '../persona/avatar_catalog.dart';
import '../persona/persona_controller.dart';
import '../persona/persona_edit_sheet.dart';
import '../persona/persona_profile_sheet.dart';
import '../settings/widgets/model_section.dart';

class CompanionHubScreen extends ConsumerWidget {
  const CompanionHubScreen({super.key});

  Future<void> _openProfile(
    BuildContext context,
    WidgetRef ref,
    PersonaConfig? persona,
  ) async {
    final edit = await showPersonaProfileSheet(context, persona);
    if (edit == true && context.mounted) {
      await showAppSheet<void>(context, child: const PersonaEditSheet());
    }
  }

  void _startWithDraft(BuildContext context, WidgetRef ref, String starter) {
    ref.read(pendingChatDraftProvider.notifier).setDraft(starter);
    context.go(AppRoutes.chat);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    final starters = [
      strings.hubStarter1,
      strings.hubStarter2,
      strings.hubStarter3,
    ];

    return AppScaffold(
      body: AppContent(
        maxWidth: AppSizes.contentMaxWidth,
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSizes.spaceSm,
            bottom: AppSizes.spaceXl,
          ),
          children: [
            _HubTopBar(onOpenProfile: _openProfile),
            const SizedBox(height: AppSizes.spaceLg),
            sectionHeader(
              context,
              strings.hubSectionStatus,
              Icons.favorite_outline_rounded,
            ),
            _CompanionStatusCard(onOpenProfile: _openProfile),
            const SizedBox(height: AppSizes.spaceLg),
            sectionHeader(
              context,
              strings.hubStartersTitle,
              Icons.chat_bubble_outline_rounded,
            ),
            sectionCard(
              context: context,
              children: [
                for (int i = 0; i < starters.length; i++)
                  _StarterRow(
                    key: ValueKey('hub-starter-$i'),
                    text: starters[i],
                    onTap: () => _startWithDraft(context, ref, starters[i]),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceLg),
            LayoutBuilder(
              builder: (context, constraints) {
                const memoryCard = _MemorySnapshotSection();
                const engineCard = _EngineSnapshotSection();

                if (constraints.maxWidth < 480) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      memoryCard,
                      SizedBox(height: AppSizes.spaceMd),
                      engineCard,
                    ],
                  );
                }

                return const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: memoryCard),
                      SizedBox(width: AppSizes.spaceMd),
                      Expanded(child: engineCard),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

typedef _OpenProfileFn =
    Future<void> Function(
      BuildContext context,
      WidgetRef ref,
      PersonaConfig? persona,
    );

class _HubTopBar extends ConsumerWidget {
  const _HubTopBar({required this.onOpenProfile});

  final _OpenProfileFn onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final persona = ref.watch(personaProvider);
    return Row(
      children: [
        const ResonanceMark(size: 24),
        const SizedBox(width: AppSizes.spaceXs),
        Expanded(
          child: Text(
            strings.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingSmall(
              context,
              color: AppColors.primaryDeepFor(context),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: strings.chatOpenProfile,
          child: InkWell(
            onTap: () => onOpenProfile(context, ref, persona),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: personaAvatar(
                context,
                name: persona?.name,
                avatarId: persona?.avatarId,
                size: AppSizes.avatarSm,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanionStatusCard extends ConsumerWidget {
  const _CompanionStatusCard({required this.onOpenProfile});

  final _OpenProfileFn onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final persona = ref.watch(personaProvider);
    final mood = ref.watch(moodProvider);
    final scheme = Theme.of(context).colorScheme;
    final name = persona?.name ?? strings.chatFallbackName;
    final nickname = persona?.nicknameForUser ?? '';
    final opt = avatarOptForId(persona?.avatarId);
    final barColor = moodColor(context, mood.current);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd + 2),
      decoration: AppBorders.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatarCircle(context, opt, AppSizes.avatarCard),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displaySmall(
                        context,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (nickname.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        fillPlaceholders(strings.personaCallsYou, {
                          'nickname': nickname,
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.spaceXs),
                    const MoodIndicator(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: mood.intensity.clamp(0, 1),
              backgroundColor: scheme.surfaceContainerHighest,
              color: barColor,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSizes.spaceMd),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      label: strings.hubOpenChat,
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => context.go(AppRoutes.chat),
                    ),
                    const SizedBox(height: AppSizes.spaceXs),
                    SecondaryButton(
                      label: strings.hubViewProfile,
                      onPressed: () => onOpenProfile(context, ref, persona),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: strings.hubOpenChat,
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => context.go(AppRoutes.chat),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: SecondaryButton(
                      label: strings.hubViewProfile,
                      onPressed: () => onOpenProfile(context, ref, persona),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MemorySnapshotSection extends ConsumerWidget {
  const _MemorySnapshotSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final facts = ref.watch(memoryFactsProvider);
    return _SnapshotCard(
      key: const ValueKey('hub-memory-card'),
      title: strings.hubMemorySnapshot,
      icon: Icons.bookmark_outline_rounded,
      headline: strings.hubMemoryCount(facts.length),
      body: facts.isNotEmpty
          ? '${facts.first.key}: ${facts.first.value}'
          : strings.hubMemoryEmpty,
      actionLabel: strings.hubViewAll,
      onTap: () => context.go(AppRoutes.memory),
    );
  }
}

class _EngineSnapshotSection extends ConsumerWidget {
  const _EngineSnapshotSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);
    final modelReady = ref.watch(modelReadyProvider);
    final scheme = Theme.of(context).colorScheme;

    final bool hasSelectedModel = settings.modelVariant.isNotEmpty;
    final String body;
    final Color dotColor;
    if (modelReady) {
      body = strings.hubEngineReady;
      dotColor = AppColors.successFor(context);
    } else if (hasSelectedModel) {
      body = strings.modelLoadingTitle;
      dotColor = AppColors.warningFor(context);
    } else {
      body = strings.modelNotInstalled;
      dotColor = scheme.outline;
    }

    return _SnapshotCard(
      key: const ValueKey('hub-engine-card'),
      title: strings.hubEngineTitle,
      icon: Icons.memory_rounded,
      headline: currentModelLabel(settings, strings),
      body: body,
      accentDotColor: dotColor,
      actionLabel: modelReady ? strings.navSettings : strings.modelChange,
      onTap: () => modelReady
          ? context.go(AppRoutes.settings)
          : context.push(AppRoutes.modelDownload),
    );
  }
}


class _StarterRow extends StatelessWidget {
  const _StarterRow({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMd,
            vertical: AppSizes.spaceSm + 2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.bodyMedium(color: scheme.onSurface),
                ),
              ),
              const SizedBox(width: AppSizes.spaceSm),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    super.key,
    required this.title,
    required this.icon,
    required this.headline,
    required this.body,
    required this.actionLabel,
    required this.onTap,
    this.accentDotColor,
  });

  final String title;
  final IconData icon;
  final String headline;
  final String body;
  final String actionLabel;
  final VoidCallback onTap;
  final Color? accentDotColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSizes.radiusCard);
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionLabel(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spaceSm),
              Text(
                headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingSmall(
                  context,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSizes.spaceXxs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (accentDotColor != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentDotColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spaceSm),
              Row(
                children: [
                  Text(
                    actionLabel,
                    style: AppTextStyles.titleSmall(
                      color: AppColors.primaryDeepFor(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primaryDeepFor(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
