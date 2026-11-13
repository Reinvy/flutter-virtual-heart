// Settings — Appearance (mode kecerahan + 4 preset gaya tema Atelier).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tokens/app_colors.dart';
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

    final styleMeta = [
      (
        style: AppThemeStyle.editorial,
        title: strings.settingsThemeEditorial,
        desc: strings.settingsThemeEditorialDesc,
      ),
      (
        style: AppThemeStyle.romantic,
        title: strings.settingsThemeRomantic,
        desc: strings.settingsThemeRomanticDesc,
      ),
      (
        style: AppThemeStyle.classic,
        title: strings.settingsThemeClassic,
        desc: strings.settingsThemeClassicDesc,
      ),
      (
        style: AppThemeStyle.botanical,
        title: strings.settingsThemeBotanical,
        desc: strings.settingsThemeBotanicalDesc,
      ),
    ];

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
                strings.settingsBrightnessMode,
                style: AppTextStyles.settingsLabel(),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: _ThemeOptionCard(
                      value: AppThemeSetting.light,
                      label: strings.settingsThemeLight,
                      icon: Icons.light_mode_outlined,
                      selected: settings.theme == AppThemeSetting.light,
                      onTap: () => _selectBrightness(ref, AppThemeSetting.light),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceXs),
                  Expanded(
                    child: _ThemeOptionCard(
                      value: AppThemeSetting.dark,
                      label: strings.settingsThemeDark,
                      icon: Icons.dark_mode_outlined,
                      selected: settings.theme == AppThemeSetting.dark,
                      onTap: () => _selectBrightness(ref, AppThemeSetting.dark),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceXs),
                  Expanded(
                    child: _ThemeOptionCard(
                      value: AppThemeSetting.system,
                      label: strings.settingsThemeSystem,
                      icon: Icons.phone_android_outlined,
                      selected: settings.theme == AppThemeSetting.system,
                      onTap: () => _selectBrightness(ref, AppThemeSetting.system),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spaceLg),
              Text(
                strings.settingsThemeStyle,
                style: AppTextStyles.settingsLabel(),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCols = constraints.maxWidth >= 280;
                  if (!twoCols) {
                    return Column(
                      children: [
                        for (int i = 0; i < styleMeta.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSizes.spaceXs),
                          _ThemeStyleCard(
                            style: styleMeta[i].style,
                            title: styleMeta[i].title,
                            subtitle: styleMeta[i].desc,
                            selected: settings.themeStyle == styleMeta[i].style,
                            onTap: () => _selectStyle(ref, styleMeta[i].style),
                          ),
                        ],
                      ],
                    );
                  }

                  final itemWidth =
                      (constraints.maxWidth - AppSizes.spaceXs) / 2;
                  return Wrap(
                    spacing: AppSizes.spaceXs,
                    runSpacing: AppSizes.spaceXs,
                    children: [
                      for (final item in styleMeta)
                        SizedBox(
                          width: itemWidth,
                          child: _ThemeStyleCard(
                            style: item.style,
                            title: item.title,
                            subtitle: item.desc,
                            selected: settings.themeStyle == item.style,
                            onTap: () => _selectStyle(ref, item.style),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectBrightness(WidgetRef ref, AppThemeSetting value) {
    if (settings.theme == value) return;
    HapticFeedback.selectionClick();
    ref
        .read(appSettingsProvider.notifier)
        .save(settings.copyWith(theme: value));
  }

  void _selectStyle(WidgetRef ref, AppThemeStyle style) {
    if (settings.themeStyle == style) return;
    HapticFeedback.selectionClick();
    ref
        .read(appSettingsProvider.notifier)
        .save(settings.copyWith(themeStyle: style));
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
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceXs,
            vertical: AppSizes.spaceSm,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected ? scheme.primaryContainer : scheme.surface,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
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

class _ThemeStyleCard extends StatelessWidget {
  const _ThemeStyleCard({
    required this.style,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final AppThemeStyle style;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = AppPalettes.resolve(style, Brightness.light);
    final dark = AppPalettes.resolve(style, Brightness.dark);
    final radius = BorderRadius.circular(AppSizes.radiusControl);

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        key: ValueKey('theme-style-${style.name}'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.durationFast,
          curve: AppDurations.curveStandard,
          padding: const EdgeInsets.all(AppSizes.spaceSm),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected ? scheme.surfaceContainerLow : scheme.surface,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SwatchPair(light: light, dark: dark),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: scheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.spaceSm),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.settingsLabel(
                  color: selected
                      ? AppColors.primaryDeepFor(context)
                      : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwatchPair extends StatelessWidget {
  const _SwatchPair({required this.light, required this.dark});

  final AppPalette light;
  final AppPalette dark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SwatchChip(palette: light, border: scheme.outlineVariant),
        const SizedBox(width: 4),
        _SwatchChip(palette: dark, border: scheme.outlineVariant),
      ],
    );
  }
}

class _SwatchChip extends StatelessWidget {
  const _SwatchChip({required this.palette, required this.border});

  final AppPalette palette;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
        border: Border.all(color: border, width: 1),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: palette.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
