// Settings — Appearance (tema, default light).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_durations.dart';
import '../../../core/design/tokens/app_sizes.dart';
import '../../../core/design/tokens/text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../models/app_settings.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'settings_section.dart';

class AppearanceSection extends ConsumerWidget {
  final AppSettings settings;
  const AppearanceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return SettingsSection(
      title: strings.settingsAppearance,
      icon: Icons.palette_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.settingsTheme,
                style: AppTextStyles.settingsLabel(),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: _ThemeOptionCard(
                      value: AppThemeSetting.light,
                      label: strings.settingsThemeLight,
                      icon: Icons.light_mode_rounded,
                      selected: settings.theme == AppThemeSetting.light,
                      onTap: () => _select(ref, AppThemeSetting.light),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceXs),
                  Expanded(
                    child: _ThemeOptionCard(
                      value: AppThemeSetting.dark,
                      label: strings.settingsThemeDark,
                      icon: Icons.dark_mode_rounded,
                      selected: settings.theme == AppThemeSetting.dark,
                      onTap: () => _select(ref, AppThemeSetting.dark),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceXs),
                  Expanded(
                    child: _ThemeOptionCard(
                      value: AppThemeSetting.system,
                      label: strings.settingsThemeSystem,
                      icon: Icons.phone_android_rounded,
                      selected: settings.theme == AppThemeSetting.system,
                      onTap: () => _select(ref, AppThemeSetting.system),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _select(WidgetRef ref, AppThemeSetting value) {
    if (settings.theme == value) return;
    HapticFeedback.selectionClick();
    ref
        .read(appSettingsProvider.notifier)
        .save(settings.copyWith(theme: value));
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final AppThemeSetting value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSizes.radiusControl);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: ValueKey('theme-option-${value.name}'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.durationFast,
          curve: AppDurations.curveStandard,
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceSm,
            vertical: AppSizes.spaceSm,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: selected
                ? LinearGradient(
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : scheme.surface,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSizes.spaceXs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
