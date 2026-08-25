// Fitur Memory (FR-12) — layar memori AI.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/utils/extensions.dart';
import '../../models/memory_fact.dart';
import 'memory_controller.dart';

class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  static const Map<MemoryCategory, IconData> _categoryIcon = {
    MemoryCategory.personal: Icons.person_outline_rounded,
    MemoryCategory.event: Icons.celebration_outlined,
    MemoryCategory.preference: Icons.favorite_border_rounded,
    MemoryCategory.date: Icons.calendar_today_outlined,
  };

  static const Map<MemoryCategory, Color> _categoryColor = {
    MemoryCategory.personal: AppColors.primary,
    MemoryCategory.event: Color(0xFFE89250),
    MemoryCategory.preference: AppColors.heartRed,
    MemoryCategory.date: AppColors.secondary,
  };

  Map<MemoryCategory, List<MemoryFact>> _grouped(List<MemoryFact> facts) {
    final map = <MemoryCategory, List<MemoryFact>>{for (final c in MemoryCategory.values) c: []};
    for (final f in facts) {
      map[f.category]!.add(f);
    }
    return map;
  }

  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.memoryResetAllTitle),
        content: Text(strings.memoryResetAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.memoryCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.heartRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.memoryReset),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(memoryFactsProvider.notifier).resetAll();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final facts = ref.watch(memoryFactsProvider);
    final grouped = _grouped(facts);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.memoryTitle),
        centerTitle: true,
        actions: [
          if (facts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: strings.memoryResetAllTitle,
              onPressed: () => _confirmResetAll(context, ref),
            ),
        ],
      ),
      body: facts.isEmpty
          ? _EmptyState(strings: strings, theme: theme)
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceXs),
              children: [
                for (final category in MemoryCategory.values)
                  if (grouped[category]!.isNotEmpty)
                    _CategorySection(
                      category: category,
                      facts: grouped[category]!,
                      label: _categoryLabel(strings, category),
                      icon: _categoryIcon[category]!,
                      color: _categoryColor[category]!,
                      onDelete: (id) => ref.read(memoryFactsProvider.notifier).deleteFact(id),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings, required this.theme});
  final AppStrings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_outlined, size: 64, color: subtleColor),
          const SizedBox(height: AppSizes.spaceMd),
          Text(
            strings.memoryEmptyTitle,
            style: theme.textTheme.titleMedium?.copyWith(color: subtleColor),
          ),
          const SizedBox(height: AppSizes.spaceXs),
          Text(
            strings.memoryEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: subtleColor),
          ),
        ],
      ),
    );
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
              Icon(icon, size: 18, color: color),
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
                  color: color.withAlpha(40),
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

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact, required this.accentColor, required this.onDelete});

  final MemoryFact fact;
  final Color accentColor;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = context.read(appStringsProvider);
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(fact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: AppColors.heartRed.withAlpha(204),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(strings.memoryDelete),
            content: Text('"${fact.key}: ${fact.value}"'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(strings.memoryCancel),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.heartRed),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(strings.memoryDelete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(fact.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border(left: BorderSide(color: accentColor, width: 3)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
