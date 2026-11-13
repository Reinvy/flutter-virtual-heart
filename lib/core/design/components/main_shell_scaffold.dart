// Komponen shared — shell navigasi 4-tab (Hub, Chat, Memory, Settings).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../active_shell_tab_provider.dart';
import '../tokens/app_durations.dart';
import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';

class MainShellScaffold extends ConsumerStatefulWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends ConsumerState<MainShellScaffold> {
  @override
  void initState() {
    super.initState();
    _syncActiveTab();
  }

  @override
  void didUpdateWidget(covariant MainShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _syncActiveTab();
    }
  }

  void _syncActiveTab() {
    final index = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeShellTabProvider.notifier).setTab(index);
    });
  }

  void _onTapTab(int index) {
    ref.read(activeShellTabProvider.notifier).setTab(index);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final currentIndex = widget.navigationShell.currentIndex;
    final scheme = Theme.of(context).colorScheme;

    final tabs = [
      (
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: strings.navHub,
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: strings.navChat,
      ),
      (
        icon: Icons.bookmark_outline_rounded,
        activeIcon: Icons.bookmark_rounded,
        label: strings.navMemory,
      ),
      (
        icon: Icons.tune_outlined,
        activeIcon: Icons.tune_rounded,
        label: strings.navSettings,
      ),
    ];

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _ShellTabItem(
                      key: ValueKey('shell-tab-$i'),
                      icon: tabs[i].icon,
                      activeIcon: tabs[i].activeIcon,
                      label: tabs[i].label,
                      selected: i == currentIndex,
                      onTap: () => _onTapTab(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellTabItem extends StatelessWidget {
  const _ShellTabItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppDurations.durationFast,
                  width: selected ? 28 : 0,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
                Icon(selected ? activeIcon : icon, size: 22, color: color),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(color: color).copyWith(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
