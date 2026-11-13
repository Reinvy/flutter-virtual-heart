// Fitur Persona (FR-03) — bottom sheet edit persona (dari settings / profil).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/confirm_dialog.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/sheet_header.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_durations.dart';
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

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceXs),
      child: Text(
        text,
        style: AppTextStyles.headingSmall(
          context,
          color: AppColors.primaryDeepFor(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: AnimatedPadding(
        duration: AppDurations.durationFast,
        curve: AppDurations.curveStandard,
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusSheet),
              ),
              border: Border(
                top: BorderSide(color: scheme.outlineVariant, width: 1),
              ),
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  appSheetHandle(context),
                  appSheetHeader(
                    context,
                    title: strings.settingsEditPersona,
                    onClose: _confirmClose,
                    closeTooltip: strings.commonClose,
                  ),
                  Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(AppSizes.spaceMd),
                      children: [
                        _label(context, strings.settingsSheetPersonaGender),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<PersonaGender>(
                            showSelectedIcon: false,
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
                                _avatarId = s.first == PersonaGender.girlfriend
                                    ? 'gf_1'
                                    : 'bf_1';
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceLg),
                        _label(context, strings.settingsSheetPersonaName),
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
                        const SizedBox(height: AppSizes.spaceLg),
                        _label(context, strings.settingsSheetHowTheyCallYou),
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
                        const SizedBox(height: AppSizes.spaceLg),
                        _label(context, strings.settingsSheetPersonality),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 520;
                            if (!twoColumns) {
                              return Column(
                                children: [
                                  for (final preset in PersonalityPreset.values)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: PersonalityOptionCard(
                                        preset: preset,
                                        selected: _personality == preset,
                                        onTap: () {
                                          setState(() {
                                            _markDirty();
                                            _personality = preset;
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              );
                            }
                            final width =
                                (constraints.maxWidth - AppSizes.spaceSm) / 2;
                            return Wrap(
                              spacing: AppSizes.spaceSm,
                              runSpacing: AppSizes.spaceSm,
                              children: [
                                for (final preset in PersonalityPreset.values)
                                  SizedBox(
                                    width: width,
                                    child: PersonalityOptionCard(
                                      preset: preset,
                                      selected: _personality == preset,
                                      compact: true,
                                      onTap: () {
                                        setState(() {
                                          _markDirty();
                                          _personality = preset;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.spaceLg),
                        _label(context, strings.personaHobbies),
                        Text(
                          strings.personaHobbiesHint,
                          style: AppTextStyles.caption(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceXs),
                        Wrap(
                          spacing: AppSizes.spaceXs,
                          runSpacing: AppSizes.spaceXs,
                          children: [
                            for (final hobby in kHobbiesList)
                              HobbyChip(
                                label: hobby,
                                isSelected: _hobbies.contains(hobby),
                                onTap: () {
                                  setState(() {
                                    _markDirty();
                                    if (!_hobbies.remove(hobby)) {
                                      _hobbies.add(hobby);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spaceLg),
                        _label(context, strings.settingsSheetChooseAvatar),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            itemCount: _currentAvatars.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSizes.spaceSm),
                            itemBuilder: (_, i) {
                              final opt = _currentAvatars[i];
                              final selected = _avatarId == opt.id;
                              return Semantics(
                                button: true,
                                selected: selected,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _markDirty();
                                      _avatarId = opt.id;
                                    });
                                  },
                                  child: avatarCircle(
                                    context,
                                    opt,
                                    64,
                                    selected: selected,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceXl),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border(
                        top: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spaceMd,
                          vertical: AppSizes.spaceSm,
                        ),
                        child: PrimaryButton(
                          label: strings.settingsSaveChanges,
                          loading: _isSaving,
                          onPressed: _save,
                        ),
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
}
