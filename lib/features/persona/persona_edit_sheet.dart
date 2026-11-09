// Fitur Persona (FR-03) — bottom sheet edit persona (dari settings).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/app_icon_button.dart';
import '../../core/design/components/confirm_dialog.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../models/persona_config.dart';
import '../notifications/notification_controller.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'avatar_catalog.dart';
import 'persona_controller.dart';
import 'persona_options.dart';

/// Bottom sheet untuk mengedit persona secara in-place (mutasi, tanpa wipe).
class PersonaEditSheet extends ConsumerStatefulWidget {
  const PersonaEditSheet({super.key});

  @override
  ConsumerState<PersonaEditSheet> createState() => _PersonaEditSheetState();
}

class _PersonaEditSheetState extends ConsumerState<PersonaEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  PersonaGender _gender = PersonaGender.girlfriend;
  PersonalityPreset _personality = PersonalityPreset.gentle;
  String _avatarId = 'gf_1';
  final Set<String> _hobbies = {};
  bool _isSaving = false;
  bool _dirty = false;

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
      _hobbies.addAll(existing.hobbies);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  List<AvatarOpt> get _currentAvatars =>
      avatarsFor(isGirlfriend: _gender == PersonaGender.girlfriend);

  void _markDirty() => _dirty = true;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
        ..avatarId = _avatarId
        ..hobbies = _hobbies.toList();
      ref.read(personaProvider.notifier).save(persona);
      await _resyncNotifications();
      _dirty = false;
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Judul notifikasi memakai nama persona — sinkronkan setelah edit.
  Future<void> _resyncNotifications() async {
    try {
      await ref
          .read(notificationProvider.notifier)
          .applySettings(ref.read(appSettingsProvider));
    } catch (_) {
      // Notifikasi bersifat opsional; kegagalan tidak boleh membatalkan edit.
    }
  }

  /// Menutup sheet; perubahan yang belum disimpan dikonfirmasi dulu.
  Future<void> _confirmClose() async {
    final strings = ref.read(appStringsProvider);
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showConfirmDialog(
      context,
      title: strings.settingsDiscardTitle,
      body: strings.settingsDiscardBody,
      confirmLabel: strings.settingsDiscard,
      cancelLabel: strings.commonCancel,
    );
    if (!mounted) return;
    if (discard) Navigator.of(context).pop();
  }

  String? _validateName(String? value) {
    final strings = ref.read(appStringsProvider);
    final text = value?.trim() ?? '';
    if (text.isEmpty) return strings.personaNameEmpty;
    if (text.length < 2) return strings.personaNameMin;
    if (text.length > 32) return strings.personaNameMax;
    return null;
  }

  String? _validateNickname(String? value) {
    final strings = ref.read(appStringsProvider);
    if ((value?.trim() ?? '').isEmpty) return strings.personaNicknameEmpty;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final sheetBg = scheme.surface;
    final subtleColor = scheme.onSurfaceVariant;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.sm,
                      AppSizes.sm,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.settingsEditPersona,
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.close_rounded,
                          onPressed: _confirmClose,
                          tooltip: strings.commonClose,
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
                            if (s.isEmpty) return;
                            HapticFeedback.selectionClick();
                            setState(() {
                              _markDirty();
                              _gender = s.first;
                              _avatarId = s.first == PersonaGender.girlfriend ? 'gf_1' : 'bf_1';
                            });
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
                          validator: _validateName,
                          onChanged: (_) => _markDirty(),
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
                          validator: _validateNickname,
                          onChanged: (_) => _markDirty(),
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
                                setState(() {
                                  _markDirty();
                                  _personality = preset;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _SheetLabel(strings.personaHobbies, subtleColor),
                        const SizedBox(height: AppSizes.xs),
                        Text(strings.personaHobbiesHint, style: AppTextStyles.timestamp()),
                        const SizedBox(height: AppSizes.sm),
                        Wrap(
                          spacing: AppSizes.sm,
                          runSpacing: AppSizes.sm,
                          children: [
                            for (final hobby in kHobbiesList)
                              HobbyChip(
                                label: hobby,
                                isSelected: _hobbies.contains(hobby),
                                onTap: () {
                                  setState(() {
                                    _markDirty();
                                    if (!_hobbies.remove(hobby)) _hobbies.add(hobby);
                                  });
                                },
                              ),
                          ],
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
                              return Semantics(
                                button: true,
                                selected: _avatarId == opt.id,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _markDirty();
                                      _avatarId = opt.id;
                                    });
                                  },
                                  child: avatarCircle(opt, 56, selected: _avatarId == opt.id),
                                ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
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
          ),
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
