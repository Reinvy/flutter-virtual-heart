import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/memory_fact.dart';
import '../../providers/objectbox_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

/// Reactive list of all persisted [MemoryFact]s, re-read whenever the screen
/// is invalidated via [memoryFactsProvider.notifier] or [ref.invalidate].
final memoryFactsProvider = NotifierProvider<MemoryFactsNotifier, List<MemoryFact>>(
  MemoryFactsNotifier.new,
);

class MemoryFactsNotifier extends Notifier<List<MemoryFact>> {
  @override
  List<MemoryFact> build() => _load();

  List<MemoryFact> _load() {
    final db = ref.read(objectBoxServiceProvider);
    return db.memoryFactBox.getAll()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void deleteFact(int id) {
    ref.read(objectBoxServiceProvider).memoryFactBox.remove(id);
    state = state.where((f) => f.id != id).toList();
  }

  void resetAll() {
    ref.read(objectBoxServiceProvider).memoryFactBox.removeAll();
    state = const [];
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  // Category metadata ──────────────────────────────────────────────────────

  static const Map<MemoryCategory, String> _categoryLabel = {
    MemoryCategory.personal: 'Personal',
    MemoryCategory.event: 'Events',
    MemoryCategory.preference: 'Preferences',
    MemoryCategory.date: 'Important Dates',
  };

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

  // Helpers ────────────────────────────────────────────────────────────────

  Map<MemoryCategory, List<MemoryFact>> _grouped(List<MemoryFact> facts) {
    final map = <MemoryCategory, List<MemoryFact>>{for (final c in MemoryCategory.values) c: []};
    for (final f in facts) {
      map[f.category]!.add(f);
    }
    return map;
  }

  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Memories?'),
        content: const Text(
          'All facts remembered by AI will be permanently deleted. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.heartRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(memoryFactsProvider.notifier).resetAll();
    }
  }

  // Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = ref.watch(memoryFactsProvider);
    final grouped = _grouped(facts);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Memory'),
        centerTitle: true,
        actions: [
          if (facts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Reset all memories',
              onPressed: () => _confirmResetAll(context, ref),
            ),
        ],
      ),
      body: facts.isEmpty
          ? _EmptyState(theme: theme)
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final category in MemoryCategory.values)
                  if (grouped[category]!.isNotEmpty)
                    _CategorySection(
                      category: category,
                      facts: grouped[category]!,
                      label: _categoryLabel[category]!,
                      icon: _categoryIcon[category]!,
                      color: _categoryColor[category]!,
                      onDelete: (id) => ref.read(memoryFactsProvider.notifier).deleteFact(id),
                    ),
              ],
            ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_outlined, size: 64, color: subtleColor),
          const SizedBox(height: 16),
          Text(
            'No memories saved yet',
            style: theme.textTheme.titleMedium?.copyWith(color: subtleColor),
          ),
          const SizedBox(height: 8),
          Text(
            'AI will remember important facts about you\nas conversations continue.',
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
        // Section header
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
        // Fact tiles
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
            title: const Text('Hapus fakta ini?'),
            content: Text('"${fact.key}: ${fact.value}"'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.heartRed),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
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
          borderRadius: BorderRadius.circular(12),
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
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
