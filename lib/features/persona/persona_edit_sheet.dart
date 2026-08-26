// Fitur Persona (FR-03) — bottom sheet edit persona (dari settings).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/app_icon_button.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/persona_config.dart';
import 'avatar_catalog.dart';
import 'persona_controller.dart';

/// Bottom sheet untuk mengedit persona secara in-place (mutasi, tanpa wipe).
class PersonaEditSheet extends ConsumerStatefulWidget {
  const PersonaEditSheet({super.key});

  @override
  ConsumerState<PersonaEditSheet> createState() => _PersonaEditSheetState();
}

class _PersonaEditSheetState extends ConsumerState<PersonaEditSheet> {
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  PersonaGender _gender = PersonaGender.girlfriend;
  PersonalityPreset _personality = PersonalityPreset.gentle;
  String _avatarId = 'gf_1';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(personaProvider);
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _nicknameCtrl.text = existing.nicknameForUser;
      _gender = existing.gender;
      _personality = existing.personalityPreset;
      _avatarId = existing.avatarId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  List<AvatarOpt> get _currentAvatars => avatarsFor(isGirlfriend: _gender == PersonaGender.girlfriend);

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.settingsPersonaNameEmpty)));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      final existing = ref.read(personaProvider);
      final persona = existing ?? PersonaConfig();
      persona
        ..name = _nameCtrl.text.trim()
        ..nicknameForUser = _nicknameCtrl.text.trim()
        ..gender = _gender
        ..personalityPreset = _personality
        ..avatarId = _avatarId;
      ref.read(personaProvider.notifier).save(persona);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final sheetBg = scheme.surface;
    final subtleColor = scheme.onSurfaceVariant;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subtleColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  Text(strings.settingsEditPersona, style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: strings.memoryCancel,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(AppSizes.md),
                children: [
                  _SheetLabel(strings.settingsSheetPersonaGender, subtleColor),
                  const SizedBox(height: AppSizes.sm),
                  SegmentedButton<PersonaGender>(
                    segments: [
                      ButtonSegment(
                        value: PersonaGender.girlfriend,
                        label: Text(strings.personaGenderGirlfriend),
                        icon: const Icon(Icons.female_rounded),
                      ),
                      ButtonSegment(
                        value: PersonaGender.boyfriend,
                        label: Text(strings.personaGenderBoyfriend),
                        icon: const Icon(Icons.male_rounded),
                      ),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (s) {
                      if (s.isNotEmpty) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _gender = s.first;
                          _avatarId = s.first == PersonaGender.girlfriend ? 'gf_1' : 'bf_1';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _SheetLabel(strings.settingsSheetPersonaName, subtleColor),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: strings.personaNameHint,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _SheetLabel(strings.settingsSheetHowTheyCallYou, subtleColor),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _nicknameCtrl,
                    decoration: InputDecoration(
                      hintText: strings.personaNicknameHint,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _SheetLabel(strings.settingsSheetPersonality, subtleColor),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: PersonalityPreset.values.map((preset) {
                      final selected = _personality == preset;
                      return ChoiceChip(
                        label: Text(_personalityLabel(strings, preset)),
                        selected: selected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _personality = preset);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _SheetLabel(strings.settingsSheetChooseAvatar, subtleColor),
                  const SizedBox(height: AppSizes.sm),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentAvatars.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
                      itemBuilder: (_, i) {
                        final opt = _currentAvatars[i];
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _avatarId = opt.id);
                          },
                          child: avatarCircle(opt, 56, selected: _avatarId == opt.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                child: PrimaryButton(
                  label: strings.settingsSaveChanges,
                  loading: _isSaving,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _personalityLabel(AppStrings strings, PersonalityPreset preset) {
    return switch (preset) {
      PersonalityPreset.gentle => strings.personaPersonalityGentle,
      PersonalityPreset.cheerful => strings.personaPersonalityCheerful,
      PersonalityPreset.mature => strings.personaPersonalityMature,
      PersonalityPreset.mysterious => strings.personaPersonalityMysterious,
    };
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SheetLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
