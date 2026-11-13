// Fitur Persona (FR-03) — layar setup/edit persona.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/app_scaffold.dart';
import '../../core/design/components/primary_button.dart';
import '../../core/design/components/resonance_mark.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/persona_config.dart';
import '../../services/ai/model_service.dart';
import 'package:virtual_heart/services/ai/model_ready_provider.dart';
import '../notifications/notification_controller.dart';
import 'package:virtual_heart/services/settings/settings_service.dart';
import 'avatar_catalog.dart';
import 'persona_options.dart';
import 'persona_controller.dart';

/// Layar setup persona. Mendukung mode buat baru dan edit.
class PersonaSetupScreen extends ConsumerStatefulWidget {
  const PersonaSetupScreen({super.key});

  @override
  ConsumerState<PersonaSetupScreen> createState() => _PersonaSetupScreenState();
}

class _PersonaSetupScreenState extends ConsumerState<PersonaSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  PersonaGender _gender = PersonaGender.girlfriend;
  PersonalityPreset _personality = PersonalityPreset.gentle;
  final Set<String> _selectedHobbies = {};
  String _selectedAvatarId = 'gf_1';
  bool _isSaving = false;

  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(personaProvider);
    _isEditing = existing != null;
    if (existing != null) {
      _nameController.text = existing.name;
      _nicknameController.text = existing.nicknameForUser;
      _gender = existing.gender;
      _personality = existing.personalityPreset;
      _selectedHobbies.addAll(existing.hobbies);
      _selectedAvatarId = existing.avatarId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  List<AvatarOpt> get _currentAvatars =>
      avatarsFor(isGirlfriend: _gender == PersonaGender.girlfriend);

  void _switchGender(PersonaGender gender) {
    if (_gender == gender) return;
    HapticFeedback.selectionClick();
    setState(() {
      _gender = gender;
      _selectedAvatarId = gender == PersonaGender.girlfriend ? 'gf_1' : 'bf_1';
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final persona = PersonaConfig(
        gender: _gender,
        name: _nameController.text.trim(),
        personalityPreset: _personality,
        hobbies: _selectedHobbies.toList(),
        nicknameForUser: _nicknameController.text.trim(),
        avatarId: _selectedAvatarId,
      );
      ref.read(personaProvider.notifier).save(persona);

      final settings = ref.read(appSettingsProvider);
      ref
          .read(appSettingsProvider.notifier)
          .save(settings.copyWith(isPersonaSetup: true));

      try {
        await ref
            .read(notificationProvider.notifier)
            .applySettings(ref.read(appSettingsProvider));
      } catch (_) {
        // Notifikasi opsional: jangan blokir alur setup.
      }

      final ready =
          (ref.read(modelServiceProvider).value?.ready ?? false) ||
          ref.read(modelReadyProvider);
      if (mounted) context.go(ready ? AppRoutes.hub : AppRoutes.modelDownload);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return AppScaffold(
      safeArea: false,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            SafeArea(bottom: false, child: _buildHeader(strings)),
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: AppSizes.spaceLg),
                child: AppContent(
                  maxWidth: 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGenderSection(strings),
                      const SizedBox(height: 28),
                      _buildAvatarSection(strings),
                      const SizedBox(height: 28),
                      _buildNameSection(strings),
                      const SizedBox(height: 20),
                      _buildNicknameSection(strings),
                      const SizedBox(height: 28),
                      _buildPersonalitySection(strings),
                      const SizedBox(height: 28),
                      _buildHobbiesSection(strings),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.pageGutter,
                    vertical: AppSizes.spaceSm,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: PrimaryButton(
                      label: strings.personaSave,
                      loading: _isSaving,
                      onPressed: _save,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings strings) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        AppSizes.spaceMd,
        AppSizes.pageGutter,
        AppSizes.spaceMd,
      ),
      child: Row(
        children: [
          const ResonanceMark(size: 32),
          const SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? strings.settingsEditPersona
                      : strings.personaCreateTitle,
                  style: AppTextStyles.displaySmall(
                    context,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.personaCreateSubtitle,
                  style: AppTextStyles.bodySmall(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: AppTextStyles.headingSmall(
          context,
          color: AppColors.primaryDeepFor(context),
        ),
      ),
    );
  }

  Widget _buildGenderSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaGenderQuestion),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 320) {
              return Column(
                children: [
                  GenderOptionCard(
                    label: strings.personaGenderGirlfriend,
                    icon: Icons.female,
                    selected: _gender == PersonaGender.girlfriend,
                    onTap: () => _switchGender(PersonaGender.girlfriend),
                  ),
                  const SizedBox(height: AppSizes.spaceXs),
                  GenderOptionCard(
                    label: strings.personaGenderBoyfriend,
                    icon: Icons.male,
                    selected: _gender == PersonaGender.boyfriend,
                    onTap: () => _switchGender(PersonaGender.boyfriend),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: GenderOptionCard(
                    label: strings.personaGenderGirlfriend,
                    icon: Icons.female,
                    selected: _gender == PersonaGender.girlfriend,
                    onTap: () => _switchGender(PersonaGender.girlfriend),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: GenderOptionCard(
                    label: strings.personaGenderBoyfriend,
                    icon: Icons.male,
                    selected: _gender == PersonaGender.boyfriend,
                    onTap: () => _switchGender(PersonaGender.boyfriend),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvatarSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaChooseAppearance),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            itemCount: _currentAvatars.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSizes.spaceSm),
            itemBuilder: (context, index) {
              final avatar = _currentAvatars[index];
              final selected = _selectedAvatarId == avatar.id;
              return Semantics(
                button: true,
                selected: selected,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedAvatarId = avatar.id);
                  },
                  child: avatarCircle(context, avatar, 72, selected: selected),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNameSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaPartnerName),
        TextFormField(
          controller: _nameController,
          style: AppTextStyles.bodyMedium(),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: strings.personaNameHint,
            prefixIcon: const Icon(Icons.badge_outlined, size: AppSizes.iconMd),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return strings.personaNameEmpty;
            if (v.trim().length < 2) return strings.personaNameMin;
            if (v.trim().length > 32) return strings.personaNameMax;
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNicknameSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaNickname),
        TextFormField(
          controller: _nicknameController,
          style: AppTextStyles.bodyMedium(),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: strings.personaNicknameHint,
            prefixIcon: const Icon(Icons.person_outline, size: AppSizes.iconMd),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return strings.personaNicknameEmpty;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPersonalitySection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaPersonality),
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
                        onTap: () => setState(() => _personality = preset),
                      ),
                    ),
                ],
              );
            }
            final width = (constraints.maxWidth - AppSizes.spaceSm) / 2;
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
                      onTap: () => setState(() => _personality = preset),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHobbiesSection(AppStrings strings) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaHobbies),
        Text(
          strings.personaHobbiesHint,
          style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: AppSizes.spaceXs,
          runSpacing: AppSizes.spaceXs,
          children: [
            for (final hobby in kHobbiesList)
              HobbyChip(
                label: hobby,
                isSelected: _selectedHobbies.contains(hobby),
                onTap: () {
                  setState(() {
                    if (_selectedHobbies.contains(hobby)) {
                      _selectedHobbies.remove(hobby);
                    } else {
                      _selectedHobbies.add(hobby);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}
