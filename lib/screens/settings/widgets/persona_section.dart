import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/persona_config.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/objectbox_provider.dart';
import 'avatar_helpers.dart';
import 'section_widgets.dart';

// ── Persona Section ───────────────────────────────────────────────────────────

class PersonaSection extends ConsumerWidget {
  final AppSettings settings;
  const PersonaSection({super.key, required this.settings});

  Future<void> _showEditSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PersonaEditSheet(),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Persona?'),
        content: const Text(
          'All persona data, memories, and mood will be deleted.\n'
          'You will need to set up your virtual partner from scratch.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.heartRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    HapticFeedback.heavyImpact();

    final db = ref.read(objectBoxServiceProvider);
    db.personaBox.removeAll();
    db.memoryFactBox.removeAll();
    db.moodStateBox.removeAll();

    final updated = settings.copyWith(isPersonaSetup: false);
    ref.read(appSettingsProvider.notifier).save(updated);
    // Router guard will redirect to /persona-setup automatically.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtleColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final db = ref.read(objectBoxServiceProvider);
    final personas = db.personaBox.getAll();
    final persona = personas.isNotEmpty ? personas.first : null;

    final List<AvatarOpt> avatars = persona?.gender == PersonaGender.boyfriend
        ? boyfriendAvatars
        : girlfriendAvatars;
    final opt = avatars.firstWhere(
      (a) => a.id == (persona?.avatarId ?? ''),
      orElse: () => avatars.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, 'Persona', Icons.favorite_rounded),
        sectionCard(
          context: context,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  avatarCircle(opt, AppSizes.avatarMd),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona?.name.isNotEmpty == true ? persona!.name : 'Not set',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (persona != null) ...[
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            '${genderLabels[persona.gender] ?? ''} · '
                            '${personalityLabels[persona.personalityPreset] ?? ''}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: subtleColor),
                          ),
                        ],
                        if (persona?.nicknameForUser.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Calls you: "${persona!.nicknameForUser}"',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: subtleColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('Edit Persona'),
              trailing: Icon(Icons.chevron_right_rounded, color: subtleColor),
              onTap: () => _showEditSheet(context),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.refresh_rounded, color: AppColors.heartRed),
              title: const Text('Reset Persona', style: TextStyle(color: AppColors.heartRed)),
              onTap: () => _confirmReset(context, ref),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }
}

// ── Persona Edit Sheet ────────────────────────────────────────────────────────

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
    final db = ref.read(objectBoxServiceProvider);
    final personas = db.personaBox.getAll();
    if (personas.isNotEmpty) {
      final p = personas.first;
      _nameCtrl.text = p.name;
      _nicknameCtrl.text = p.nicknameForUser;
      _gender = p.gender;
      _personality = p.personalityPreset;
      _avatarId = p.avatarId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  List<AvatarOpt> get _currentAvatars =>
      _gender == PersonaGender.girlfriend ? girlfriendAvatars : boyfriendAvatars;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Persona name cannot be empty')));
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      final db = ref.read(objectBoxServiceProvider);
      final existing = db.personaBox.getAll();
      final persona = existing.isNotEmpty ? existing.first : PersonaConfig();
      persona
        ..name = _nameCtrl.text.trim()
        ..nicknameForUser = _nicknameCtrl.text.trim()
        ..gender = _gender
        ..personalityPreset = _personality
        ..avatarId = _avatarId;
      db.personaBox.put(persona);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.surfaceAlt : AppColors.surfaceAltLight;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight).withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  Text('Edit Persona', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
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
                  SheetLabel('Persona Gender'),
                  const SizedBox(height: AppSizes.sm),
                  SegmentedButton<PersonaGender>(
                    segments: const [
                      ButtonSegment(
                        value: PersonaGender.girlfriend,
                        label: Text('Girlfriend'),
                        icon: Icon(Icons.female_rounded),
                      ),
                      ButtonSegment(
                        value: PersonaGender.boyfriend,
                        label: Text('Boyfriend'),
                        icon: Icon(Icons.male_rounded),
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
                  SheetLabel('Persona Name'),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'E.g.: Luna, Aria, Rei...',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SheetLabel('How They Call You'),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _nicknameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'E.g.: Honey, Babe, Dear...',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SheetLabel('Personality'),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: PersonalityPreset.values.map((preset) {
                      final selected = _personality == preset;
                      return ChoiceChip(
                        label: Text(personalityLabels[preset] ?? ''),
                        selected: selected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _personality = preset);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SheetLabel('Choose Avatar'),
                  const SizedBox(height: AppSizes.sm),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentAvatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
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
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet label ───────────────────────────────────────────────────────────────

class SheetLabel extends StatelessWidget {
  final String text;
  const SheetLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
