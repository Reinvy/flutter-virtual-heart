// Fitur Memory (FR-12) — layar memori AI (daftar + pencarian + hapus).
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/app_icon_badge.dart';
import '../../core/design/components/app_icon_button.dart';
import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/confirm_dialog.dart';
import '../../core/design/components/empty_state.dart';
import '../../core/design/components/section_card.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/memory_fact.dart';
import 'memory_controller.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  static const Map<MemoryCategory, IconData> _categoryIcon = {
    MemoryCategory.personal: Icons.person_outline_rounded,
    MemoryCategory.event: Icons.celebration_outlined,
    MemoryCategory.preference: Icons.favorite_border_rounded,
    MemoryCategory.date: Icons.calendar_today_outlined,
  };

  static Color _categoryColor(BuildContext context, MemoryCategory category) {
    return switch (category) {
      MemoryCategory.personal => Theme.of(context).colorScheme.primary,
      MemoryCategory.event => Theme.of(context).colorScheme.secondary,
      MemoryCategory.preference => AppColors.accentDeepFor(context),
      MemoryCategory.date => AppColors.goldTextFor(context),
    };
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  Map<MemoryCategory, List<MemoryFact>> _grouped(List<MemoryFact> facts) {
    final map = <MemoryCategory, List<MemoryFact>>{
      for (final c in MemoryCategory.values) c: [],
    };
    for (final f in facts) {
      map[f.category]!.add(f);
    }
    return map;
  }

  List<MemoryFact> _filter(List<MemoryFact> facts) {
    if (_query.isEmpty) return facts;
    return facts
        .where(
          (f) =>
              f.key.toLowerCase().contains(_query) ||
              f.value.toLowerCase().contains(_query),
        )
        .toList();
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.memoryResetAllTitle,
      body: strings.memoryResetAllBody,
      confirmLabel: strings.memoryReset,
      cancelLabel: strings.commonCancel,
    );
    if (confirmed) {
      ref.read(memoryFactsProvider.notifier).resetAll();
      _clearSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final allFacts = ref.watch(memoryFactsProvider);
    final facts = _filter(allFacts);
    final grouped = _grouped(facts);
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(
        actions: [
          if (allFacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.spaceXs),
              child: AppIconButton(
                icon: Icons.delete_sweep_outlined,
                tooltip: strings.memoryResetAllTitle,
                onPressed: () => _confirmResetAll(context, ref),
              ),
            ),
        ],
      ),
      body: AppContent(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.memoryTitle,
                      style: AppTextStyles.displaySmall(color: scheme.onSurface),
                    ),
                  ),
                  if (allFacts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        '${allFacts.length}',
                        style: AppTextStyles.badge(
                          color: AppColors.primaryDeepFor(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            if (allFacts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: strings.memorySearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: AppIconButton(
                              icon: Icons.close_rounded,
                              tooltip: strings.commonClose,
                              onPressed: _clearSearch,
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusBubble),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusBubble),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusBubble),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: allFacts.isEmpty
                  ? EmptyState(
                      bloom: true,
                      icon: Icons.psychology_outlined,
                      title: strings.memoryEmptyTitle,
                      body: strings.memoryEmptyBody,
                    )
                  : facts.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: strings.memorySearchEmptyTitle,
                      body: strings.memorySearchEmptyBody,
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: AppSizes.spaceXl),
                      children: [
                        for (final category in MemoryCategory.values)
                          if (grouped[category]!.isNotEmpty)
                            _CategorySection(
                              facts: grouped[category]!,
                              label: _categoryLabel(strings, category),
                              icon: _categoryIcon[category]!,
                              color: _categoryColor(context, category),
                              onDelete: (id) => ref
                                  .read(memoryFactsProvider.notifier)
                                  .deleteFact(id),
                            ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _categoryLabel(AppStrings strings, MemoryCategory category) {
    return switch (category) {
      MemoryCategory.personal => strings.memoryCategoryPersonal,
      MemoryCategory.event => strings.memoryCategoryEvent,
      MemoryCategory.preference => strings.memoryCategoryPreference,
      MemoryCategory.date => strings.memoryCategoryDate,
    };
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.facts,
    required this.label,
    required this.icon,
    required this.color,
    required this.onDelete,
  });

  final List<MemoryFact> facts;
  final String label;
  final IconData icon;
  final Color color;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spaceXxs,
            AppSizes.spaceMd,
            AppSizes.spaceXxs,
            10,
          ),
          child: Row(
            children: [
              AppIconBadge(icon: icon, color: color),
              const SizedBox(width: AppSizes.spaceXs),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionLabel(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceXs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${facts.length}',
                  style: AppTextStyles.badge(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        sectionCard(
          context: context,
          children: [
            for (final fact in facts)
              _FactTile(fact: fact, accentColor: color, onDelete: onDelete),
          ],
        ),
        const SizedBox(height: AppSizes.spaceXs),
      ],
    );
  }
}

class _FactTile extends ConsumerWidget {
  const _FactTile({
    required this.fact,
    required this.accentColor,
    required this.onDelete,
  });

  final MemoryFact fact;
  final Color accentColor;
  final void Function(int id) onDelete;

  Future<void> _confirmDelete(BuildContext context, AppStrings strings) async {
    final confirmed = await showConfirmDialog(
      context,
      title: strings.memoryDelete,
      body: '"${fact.key}: ${fact.value}"',
      confirmLabel: strings.memoryDelete,
      cancelLabel: strings.commonCancel,
    );
    if (confirmed) onDelete(fact.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSizes.radiusControl);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceXs,
        vertical: AppSizes.spaceXxs,
      ),
      child: Dismissible(
        key: ValueKey(fact.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceLg),
          decoration: BoxDecoration(color: scheme.error, borderRadius: radius),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return showConfirmDialog(
            context,
            title: strings.memoryDelete,
            body: '"${fact.key}: ${fact.value}"',
            confirmLabel: strings.memoryDelete,
            cancelLabel: strings.commonCancel,
          );
        },
        onDismissed: (_) => onDelete(fact.id),
        child: Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: accentColor.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceMd,
              vertical: AppSizes.spaceSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fact.key,
                        style: AppTextStyles.bodySmall(
                          color: scheme.onSurfaceVariant,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fact.value,
                        style: AppTextStyles.bodyLarge(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fact.sourceSnippet != null)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSizes.spaceXs),
                        child: Tooltip(
                          message: fact.sourceSnippet!,
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: AppSizes.iconSm,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    AppIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: strings.memoryDelete,
                      onPressed: () => _confirmDelete(context, strings),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
