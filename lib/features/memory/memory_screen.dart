// Fitur Memory (FR-12) — layar memori AI (daftar + pencarian + hapus).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/confirm_dialog.dart';
import '../../core/design/components/empty_state.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
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

  static const Map<MemoryCategory, Color> _categoryColor = {
    MemoryCategory.personal: AppColors.primaryDeep,
    MemoryCategory.event: AppColors.gold,
    MemoryCategory.preference: AppColors.accent,
    MemoryCategory.date: AppColors.secondary,
  };

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
    final map = <MemoryCategory, List<MemoryFact>>{for (final c in MemoryCategory.values) c: []};
    for (final f in facts) {
      map[f.category]!.add(f);
    }
    return map;
  }

  List<MemoryFact> _filter(List<MemoryFact> facts) {
    if (_query.isEmpty) return facts;
    return facts
        .where(
          (f) => f.key.toLowerCase().contains(_query) || f.value.toLowerCase().contains(_query),
        )
        .toList();
  }

  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.memoryResetAllTitle,
      body: strings.memoryResetAllBody,
      confirmLabel: strings.memoryReset,
    );
    if (confirmed) {
      ref.read(memoryFactsProvider.notifier).resetAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final allFacts = ref.watch(memoryFactsProvider);
    final facts = _filter(allFacts);
    final grouped = _grouped(facts);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.memoryTitle),
        centerTitle: true,
        actions: [
          if (allFacts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: strings.memoryResetAllTitle,
              onPressed: () => _confirmResetAll(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          if (allFacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spaceMd,
                AppSizes.spaceXs,
                AppSizes.spaceMd,
                AppSizes.spaceXs,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: strings.memorySearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  isDense: true,
                ),
              ),
            ),
          Expanded(
            child: allFacts.isEmpty
                ? EmptyState(
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
                            category: category,
                            facts: grouped[category]!,
                            label: _categoryLabel(strings, category),
                            icon: _categoryIcon[category]!,
                            color: _categoryColor[category]!,
                            onDelete: (id) =>
                                ref.read(memoryFactsProvider.notifier).deleteFact(id),
                          ),
                    ],
                  ),
          ),
        ],
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
    required this.category,
    required this.facts,
    required this.label,
    required this.icon,
    required this.color,
    required this.onDelete,
  });

  final MemoryCategory category;
  final List<MemoryFact> facts;
  final String label;
  final IconData icon;
  final Color color;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${facts.length}',
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
        ...facts.map((fact) => _FactTile(fact: fact, accentColor: color, onDelete: onDelete)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _FactTile extends ConsumerWidget {
  const _FactTile({required this.fact, required this.accentColor, required this.onDelete});

  final MemoryFact fact;
  final Color accentColor;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(fact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return showConfirmDialog(
          context,
          title: strings.memoryDelete,
          body: '"${fact.key}: ${fact.value}"',
          confirmLabel: strings.memoryDelete,
        );
      },
      onDismissed: (_) => onDelete(fact.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(Icons.favorite_rounded, size: 14, color: accentColor),
          title: Text(
            fact.key,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            fact.value,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
          ),
          trailing: fact.sourceSnippet != null
              ? Tooltip(
                  message: fact.sourceSnippet!,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: AppSizes.iconSm,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
