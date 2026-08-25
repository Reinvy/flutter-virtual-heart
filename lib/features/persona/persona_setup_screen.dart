// Fitur Persona (FR-03) — layar setup/edit persona.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/primary_button.dart';
import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_sizes.dart';
import '../../core/design/tokens/text_styles.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../models/persona_config.dart';
import '../settings/settings_controller.dart';
import 'avatar_catalog.dart';
import 'persona_controller.dart';

/// Layar setup persona. Mendukung dua mode:
/// - **Buat baru**: jika belum ada persona (isPersonaSetup=false).
/// - **Edit**: jika persona sudah ada — form ter-prefill, simpan memutasi
///   in-place tanpa menghapus data lain.
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

  /// Apakah sedang mengedit persona yang sudah ada.
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

  List<AvatarOpt> get _currentAvatars => avatarsFor(isGirlfriend: _gender == PersonaGender.girlfriend);

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
      // Buat PersonaConfig baru; controller mempertahankan id saat edit.
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
      ref.read(appSettingsProvider.notifier).save(settings.copyWith(isPersonaSetup: true));

      if (mounted) context.go(AppRoutes.modelDownload);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(strings),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSizes.xl, 0, AppSizes.xl, AppSizes.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGenderSection(strings),
                      const SizedBox(height: AppSizes.xl),
                      _buildAvatarSection(strings),
                      const SizedBox(height: AppSizes.xl),
                      _buildNameSection(strings),
                      const SizedBox(height: AppSizes.xl),
                      _buildPersonalitySection(strings),
                      const SizedBox(height: AppSizes.xl),
                      _buildHobbiesSection(strings),
                      const SizedBox(height: AppSizes.xl),
                      _buildNicknameSection(strings),
                    ],
                  ),
                ),
              ),
              _buildSaveButton(strings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.xl, AppSizes.lg, AppSizes.xl, AppSizes.lg),
      child: Row(
        children: [
          const Icon(Icons.favorite, size: AppSizes.iconMd, color: AppColors.heartRed),
          const SizedBox(width: AppSizes.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? strings.settingsEditPersona : strings.personaCreateTitle,
                style: AppTextStyles.headingLarge(),
              ),
              Text(strings.personaCreateSubtitle, style: AppTextStyles.moodIndicator()),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0, duration: 500.ms);
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(label, style: AppTextStyles.headingSmall(color: AppColors.primary)),
    );
  }

  Widget _buildGenderSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaGenderQuestion),
        Row(
          children: [
            Expanded(
              child: _GenderCard(
                label: strings.personaGenderGirlfriend,
                icon: Icons.female,
                selected: _gender == PersonaGender.girlfriend,
                onTap: () => _switchGender(PersonaGender.girlfriend),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _GenderCard(
                label: strings.personaGenderBoyfriend,
                icon: Icons.male,
                selected: _gender == PersonaGender.boyfriend,
                onTap: () => _switchGender(PersonaGender.boyfriend),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  Widget _buildAvatarSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaChooseAppearance),
        Wrap(
          spacing: AppSizes.md,
          runSpacing: AppSizes.md,
          children: [
            for (final avatar in _currentAvatars)
              _AvatarTile(
                option: avatar,
                isGirlfriend: _gender == PersonaGender.girlfriend,
                isSelected: _selectedAvatarId == avatar.id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedAvatarId = avatar.id);
                },
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildNameSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaPartnerName),
        TextFormField(
          controller: _nameController,
          style: AppTextStyles.bodyMedium(),
          cursorColor: AppColors.primary,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(hint: strings.personaNameHint, icon: Icons.badge_outlined),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return strings.personaNameEmpty;
            if (v.trim().length < 2) return strings.personaNameMin;
            return null;
          },
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildPersonalitySection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaPersonality),
        ...PersonalityPreset.values.map((preset) {
          final data = _personalityData(strings, preset);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: _PersonalityCard(
              emoji: data.$1,
              label: data.$2,
              description: data.$3,
              isSelected: _personality == preset,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _personality = preset);
              },
            ),
          );
        }),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }

  (String, String, String) _personalityData(AppStrings strings, PersonalityPreset preset) {
    return switch (preset) {
      PersonalityPreset.gentle => (
        '🌸',
        strings.personaPersonalityGentle,
        strings.personaPersonalityGentleDesc,
      ),
      PersonalityPreset.cheerful => (
        '✨',
        strings.personaPersonalityCheerful,
        strings.personaPersonalityCheerfulDesc,
      ),
      PersonalityPreset.mature => (
        '🌙',
        strings.personaPersonalityMature,
        strings.personaPersonalityMatureDesc,
      ),
      PersonalityPreset.mysterious => (
        '🔮',
        strings.personaPersonalityMysterious,
        strings.personaPersonalityMysteriousDesc,
      ),
    };
  }

  Widget _buildHobbiesSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaHobbies),
        Text(strings.personaHobbiesHint, style: AppTextStyles.timestamp()),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            for (final hobby in kHobbiesList)
              _HobbyChip(
                label: hobby,
                isSelected: _selectedHobbies.contains(hobby),
                onTap: () {
                  HapticFeedback.selectionClick();
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
    ).animate().fadeIn(duration: 500.ms, delay: 500.ms);
  }

  Widget _buildNicknameSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(strings.personaNickname),
        TextFormField(
          controller: _nicknameController,
          style: AppTextStyles.bodyMedium(),
          cursorColor: AppColors.primary,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(
            hint: strings.personaNicknameHint,
            icon: Icons.person_outline,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return strings.personaNicknameEmpty;
            return null;
          },
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 600.ms);
  }

  Widget _buildSaveButton(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.xl, AppSizes.md, AppSizes.xl, AppSizes.lg),
      child: PrimaryButton(
        label: strings.personaSave,
        loading: _isSaving,
        onPressed: _save,
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 700.ms);
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint(),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: AppSizes.iconMd),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

/// Daftar hobi pilihan (katalog tunggal).
const kHobbiesList = [
  'Reading',
  'Music',
  'Cooking',
  'Sports',
  'Watching Movies',
  'Gaming',
  'Art & Design',
  'Traveling',
  'Yoga & Meditation',
  'Anime & Manga',
  'Photography',
  'Writing',
];

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 32),
            const SizedBox(height: AppSizes.xs),
            Text(
              label,
              style: AppTextStyles.settingsLabel(
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final AvatarOpt option;
  final bool isGirlfriend;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.option,
    required this.isGirlfriend,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              option.accent.withAlpha(isSelected ? 200 : 100),
              option.base.withAlpha(isSelected ? 220 : 120),
            ],
          ),
          border: Border.all(color: isSelected ? option.base : Colors.transparent, width: 2.5),
          boxShadow: isSelected
              ? [BoxShadow(color: option.base.withAlpha(100), blurRadius: 12, spreadRadius: 2)]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isGirlfriend ? Icons.face_retouching_natural : Icons.person,
              color: Colors.white.withAlpha(220),
              size: 32,
            ),
            if (isSelected)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: option.base,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonalityCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonalityCard({
    required this.emoji,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.headingSmall(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(description, style: AppTextStyles.moodIndicator()),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: AppSizes.iconMd),
          ],
        ),
      ),
    );
  }
}

class _HobbyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _HobbyChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: 1.5),
        ),
        child: Text(
          label,
          style: AppTextStyles.settingsLabel(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
