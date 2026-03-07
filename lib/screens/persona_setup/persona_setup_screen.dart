import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/persona_config.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/objectbox_provider.dart';
import '../../providers/router_provider.dart';

// ── Avatar catalogue ──────────────────────────────────────────────────────────

class _AvatarOption {
  final String id;
  final Color baseColor;
  final Color accentColor;
  const _AvatarOption({required this.id, required this.baseColor, required this.accentColor});
}

const _girlfriendAvatars = <_AvatarOption>[
  _AvatarOption(id: 'gf_1', baseColor: Color(0xFFC2507A), accentColor: Color(0xFFE8839F)),
  _AvatarOption(id: 'gf_2', baseColor: Color(0xFF7B5EA7), accentColor: Color(0xFFA882D4)),
  _AvatarOption(id: 'gf_3', baseColor: Color(0xFFE8506A), accentColor: Color(0xFFFF8090)),
  _AvatarOption(id: 'gf_4', baseColor: Color(0xFFD4739A), accentColor: Color(0xFFEEA0C0)),
  _AvatarOption(id: 'gf_5', baseColor: Color(0xFF9B6EBA), accentColor: Color(0xFFBE99DD)),
  _AvatarOption(id: 'gf_6', baseColor: Color(0xFFC47BAA), accentColor: Color(0xFFE0A8CA)),
];

const _boyfriendAvatars = <_AvatarOption>[
  _AvatarOption(id: 'bf_1', baseColor: Color(0xFF5B8CCC), accentColor: Color(0xFF88B4E8)),
  _AvatarOption(id: 'bf_2', baseColor: Color(0xFF7B5EA7), accentColor: Color(0xFFA882D4)),
  _AvatarOption(id: 'bf_3', baseColor: Color(0xFF3D8B6E), accentColor: Color(0xFF68B095)),
  _AvatarOption(id: 'bf_4', baseColor: Color(0xFF4E7AA0), accentColor: Color(0xFF7BA8CC)),
  _AvatarOption(id: 'bf_5', baseColor: Color(0xFF6472B5), accentColor: Color(0xFF8E9CD8)),
  _AvatarOption(id: 'bf_6', baseColor: Color(0xFF5D9E8C), accentColor: Color(0xFF87C4B5)),
];

// ── Personality data ──────────────────────────────────────────────────────────

class _PersonalityData {
  final String label;
  final String description;
  final String emoji;
  const _PersonalityData(this.label, this.description, this.emoji);
}

const _personalityMap = <PersonalityPreset, _PersonalityData>{
  PersonalityPreset.gentle: _PersonalityData(
    'Lembut',
    'Penyayang, hangat, dan selalu ada untukmu',
    '🌸',
  ),
  PersonalityPreset.cheerful: _PersonalityData(
    'Ceria',
    'Penuh semangat, suka bercanda, dan menghibur',
    '✨',
  ),
  PersonalityPreset.mature: _PersonalityData('Dewasa', 'Bijak, tenang, dan dapat diandalkan', '🌙'),
  PersonalityPreset.mysterious: _PersonalityData(
    'Misterius',
    'Intrigin, penuh teka-teki, dan memukau',
    '🔮',
  ),
};

// ── Hobbies catalogue ─────────────────────────────────────────────────────────

const _hobbiesList = [
  'Membaca',
  'Musik',
  'Memasak',
  'Olahraga',
  'Menonton Film',
  'Gaming',
  'Seni & Desain',
  'Traveling',
  'Yoga & Meditasi',
  'Anime & Manga',
  'Fotografi',
  'Menulis',
];

// ── Screen ────────────────────────────────────────────────────────────────────

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

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  List<_AvatarOption> get _currentAvatars =>
      _gender == PersonaGender.girlfriend ? _girlfriendAvatars : _boyfriendAvatars;

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
      final db = ref.read(objectBoxServiceProvider);
      db.personaBox.removeAll();

      final persona = PersonaConfig(
        gender: _gender,
        name: _nameController.text.trim(),
        personalityPreset: _personality,
        hobbies: _selectedHobbies.toList(),
        nicknameForUser: _nicknameController.text.trim(),
        avatarId: _selectedAvatarId,
      );
      db.personaBox.put(persona);

      final settings = ref.read(appSettingsProvider);
      settings.isPersonaSetup = true;
      ref.read(appSettingsProvider.notifier).save(settings);

      if (mounted) context.go(AppRoutes.modelDownload);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSizes.xl, 0, AppSizes.xl, AppSizes.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGenderSection(),
                      const SizedBox(height: AppSizes.xl),
                      _buildAvatarSection(),
                      const SizedBox(height: AppSizes.xl),
                      _buildNameSection(),
                      const SizedBox(height: AppSizes.xl),
                      _buildPersonalitySection(),
                      const SizedBox(height: AppSizes.xl),
                      _buildHobbiesSection(),
                      const SizedBox(height: AppSizes.xl),
                      _buildNicknameSection(),
                    ],
                  ),
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.xl, AppSizes.lg, AppSizes.xl, AppSizes.lg),
      child: Row(
        children: [
          const Icon(Icons.favorite, size: AppSizes.iconMd, color: AppColors.heartRed),
          const SizedBox(width: AppSizes.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buat Persona', style: AppTextStyles.headingLarge()),
              Text('Kenalkan pasangan virtualmu 💕', style: AppTextStyles.moodIndicator()),
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

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Saya ingin teman...'),
        Row(
          children: [
            Expanded(
              child: _GenderCard(
                label: 'Perempuan',
                icon: Icons.female,
                selected: _gender == PersonaGender.girlfriend,
                onTap: () => _switchGender(PersonaGender.girlfriend),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: _GenderCard(
                label: 'Laki-laki',
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

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Pilih tampilan'),
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

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Nama pasanganku'),
        TextFormField(
          controller: _nameController,
          style: AppTextStyles.bodyMedium(),
          cursorColor: AppColors.primary,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(hint: 'Misal: Luna, Arya...', icon: Icons.badge_outlined),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
            if (v.trim().length < 2) return 'Minimal 2 karakter';
            return null;
          },
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildPersonalitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Kepribadian'),
        ...PersonalityPreset.values.map((preset) {
          final data = _personalityMap[preset]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: _PersonalityCard(
              emoji: data.emoji,
              label: data.label,
              description: data.description,
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

  Widget _buildHobbiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Hobi & minat (opsional)'),
        Text(
          'Pilih beberapa untuk membuat percakapan lebih personal',
          style: AppTextStyles.timestamp(),
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: [
            for (final hobby in _hobbiesList)
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

  Widget _buildNicknameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Cara ia memanggilku'),
        TextFormField(
          controller: _nicknameController,
          style: AppTextStyles.bodyMedium(),
          cursorColor: AppColors.primary,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration(
            hint: 'Misal: Kak, Sayang, Mas...',
            icon: Icons.person_outline,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Panggilan tidak boleh kosong';
            return null;
          },
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 600.ms);
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.xl, AppSizes.md, AppSizes.xl, AppSizes.lg),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withAlpha(100),
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                )
              : Text('Mulai Berkenalan 💕', style: AppTextStyles.button()),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 700.ms);
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint(),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: AppSizes.iconMd),
      filled: true,
      fillColor: AppColors.surface,
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
        borderSide: const BorderSide(color: AppColors.heartRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.heartRed, width: 1.5),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(30) : AppColors.surface,
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
  final _AvatarOption option;
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
              option.accentColor.withAlpha(isSelected ? 200 : 100),
              option.baseColor.withAlpha(isSelected ? 220 : 120),
            ],
          ),
          border: Border.all(color: isSelected ? option.baseColor : Colors.transparent, width: 2.5),
          boxShadow: isSelected
              ? [BoxShadow(color: option.baseColor.withAlpha(100), blurRadius: 12, spreadRadius: 2)]
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
                    color: option.baseColor,
                    border: Border.all(color: AppColors.background, width: 1.5),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.surface,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(40) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
            width: 1.5,
          ),
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
