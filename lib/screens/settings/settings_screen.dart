import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/message.dart';
import '../../data/models/persona_config.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/objectbox_provider.dart';

// ── Avatar data ───────────────────────────────────────────────────────────────

class _AvatarOpt {
  final String id;
  final Color base;
  final Color accent;
  const _AvatarOpt({required this.id, required this.base, required this.accent});
}

const _girlfriendAvatars = <_AvatarOpt>[
  _AvatarOpt(id: 'gf_1', base: Color(0xFFC2507A), accent: Color(0xFFE8839F)),
  _AvatarOpt(id: 'gf_2', base: Color(0xFF7B5EA7), accent: Color(0xFFA882D4)),
  _AvatarOpt(id: 'gf_3', base: Color(0xFFE8506A), accent: Color(0xFFFF8090)),
  _AvatarOpt(id: 'gf_4', base: Color(0xFFD4739A), accent: Color(0xFFEEA0C0)),
  _AvatarOpt(id: 'gf_5', base: Color(0xFF9B6EBA), accent: Color(0xFFBE99DD)),
  _AvatarOpt(id: 'gf_6', base: Color(0xFFC47BAA), accent: Color(0xFFE0A8CA)),
];

const _boyfriendAvatars = <_AvatarOpt>[
  _AvatarOpt(id: 'bf_1', base: Color(0xFF5B8CCC), accent: Color(0xFF88B4E8)),
  _AvatarOpt(id: 'bf_2', base: Color(0xFF7B5EA7), accent: Color(0xFFA882D4)),
  _AvatarOpt(id: 'bf_3', base: Color(0xFF3D8B6E), accent: Color(0xFF68B095)),
  _AvatarOpt(id: 'bf_4', base: Color(0xFF4E7AA0), accent: Color(0xFF7BA8CC)),
  _AvatarOpt(id: 'bf_5', base: Color(0xFF6472B5), accent: Color(0xFF8E9CD8)),
  _AvatarOpt(id: 'bf_6', base: Color(0xFF5D9E8C), accent: Color(0xFF87C4B5)),
];

const _personalityLabels = <PersonalityPreset, String>{
  PersonalityPreset.gentle: 'Lembut 🌸',
  PersonalityPreset.cheerful: 'Ceria ✨',
  PersonalityPreset.mature: 'Dewasa 🌙',
  PersonalityPreset.mysterious: 'Misterius 🔮',
};

const _genderLabels = <PersonaGender, String>{
  PersonaGender.girlfriend: 'Girlfriend',
  PersonaGender.boyfriend: 'Boyfriend',
};

// ── Avatar circle widget ──────────────────────────────────────────────────────

Widget _avatarCircle(_AvatarOpt opt, double size, {bool selected = false}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [opt.accent, opt.base]),
      border: selected
          ? Border.all(color: AppColors.primary, width: 2.5)
          : Border.all(color: Colors.transparent, width: 2.5),
      boxShadow: selected
          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)]
          : [],
    ),
    child: Center(
      child: Text(
        '♥',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: size * 0.38),
      ),
    ),
  );
}

// ── Section header ────────────────────────────────────────────────────────────

Widget _sectionHeader(BuildContext context, String title, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.sm, left: AppSizes.xs),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm + 2, color: AppColors.primary),
        const SizedBox(width: AppSizes.sm),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

// ── Section card ──────────────────────────────────────────────────────────────

Widget _sectionCard({required BuildContext context, required List<Widget> children}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.surface : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    child: Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            Divider(
              height: 1,
              thickness: 1,
              indent: AppSizes.md,
              color: isDark ? AppColors.surfaceAlt : const Color(0xFFEFE8F5),
            ),
        ],
      ],
    ),
  );
}

// ── Settings Screen ───────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.background : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: AppSizes.iconMd),
          onPressed: () => context.pop(),
        ),
        title: Text('Pengaturan', style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
        children: [
          _PersonaSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          _AppearanceSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          _LanguageSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          _VoiceSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          _NotificationsSection(settings: settings),
          const SizedBox(height: AppSizes.md),
          const _DataPrivacySection(),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

// ── Persona Section ───────────────────────────────────────────────────────────

class _PersonaSection extends ConsumerWidget {
  final AppSettings settings;
  const _PersonaSection({required this.settings});

  Future<void> _showEditSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PersonaEditSheet(),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Persona?'),
        content: const Text(
          'Semua data persona, memori, dan mood akan dihapus.\n'
          'Kamu perlu menyetel ulang pasangan virtualmu dari awal.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
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

    final updated = ref.read(appSettingsProvider);
    updated.isPersonaSetup = false;
    ref.read(appSettingsProvider.notifier).save(updated);
    // Router guard will redirect to /persona-setup automatically.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(objectBoxServiceProvider);
    final personas = db.personaBox.getAll();
    final persona = personas.isNotEmpty ? personas.first : null;

    final List<_AvatarOpt> avatars = persona?.gender == PersonaGender.boyfriend
        ? _boyfriendAvatars
        : _girlfriendAvatars;
    final opt = avatars.firstWhere(
      (a) => a.id == (persona?.avatarId ?? ''),
      orElse: () => avatars.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Persona', Icons.favorite_rounded),
        _sectionCard(
          context: context,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  _avatarCircle(opt, AppSizes.avatarMd),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona?.name.isNotEmpty == true ? persona!.name : 'Belum disetel',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (persona != null) ...[
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            '${_genderLabels[persona.gender] ?? ''} · '
                            '${_personalityLabels[persona.personalityPreset] ?? ''}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        if (persona?.nicknameForUser.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Memanggilmu: "${persona!.nicknameForUser}"',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
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
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
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

class _PersonaEditSheet extends ConsumerStatefulWidget {
  const _PersonaEditSheet();

  @override
  ConsumerState<_PersonaEditSheet> createState() => _PersonaEditSheetState();
}

class _PersonaEditSheetState extends ConsumerState<_PersonaEditSheet> {
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

  List<_AvatarOpt> get _currentAvatars =>
      _gender == PersonaGender.girlfriend ? _girlfriendAvatars : _boyfriendAvatars;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama persona tidak boleh kosong')));
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
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                children: [
                  Text('Edit Persona', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
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
                  _SheetLabel('Gender Persona'),
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
                  _SheetLabel('Nama Persona'),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Luna, Aria, Rei...',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _SheetLabel('Cara Memanggil Kamu'),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _nicknameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Sayang, Kak, Tuan...',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _SheetLabel('Kepribadian'),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: PersonalityPreset.values.map((preset) {
                      final selected = _personality == preset;
                      return ChoiceChip(
                        label: Text(_personalityLabels[preset] ?? ''),
                        selected: selected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _personality = preset);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _SheetLabel('Pilih Avatar'),
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
                          child: _avatarCircle(opt, 56, selected: _avatarId == opt.id),
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
                      : const Text('Simpan Perubahan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
  );
}

// ── Appearance Section ────────────────────────────────────────────────────────

class _AppearanceSection extends ConsumerWidget {
  final AppSettings settings;
  const _AppearanceSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Tampilan', Icons.palette_outlined),
        _sectionCard(
          context: context,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppSizes.sm),
                  SegmentedButton<AppTheme>(
                    segments: const [
                      ButtonSegment(
                        value: AppTheme.dark,
                        label: Text('Gelap'),
                        icon: Icon(Icons.dark_mode_rounded),
                      ),
                      ButtonSegment(
                        value: AppTheme.light,
                        label: Text('Terang'),
                        icon: Icon(Icons.light_mode_rounded),
                      ),
                      ButtonSegment(
                        value: AppTheme.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.phone_android_rounded),
                      ),
                    ],
                    selected: {settings.theme},
                    onSelectionChanged: (s) {
                      if (s.isNotEmpty) {
                        HapticFeedback.selectionClick();
                        final updated = settings..theme = s.first;
                        ref.read(appSettingsProvider.notifier).save(updated);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 60.ms).slideY(begin: 0.04, end: 0);
  }
}

// ── Language Section ──────────────────────────────────────────────────────────

class _LanguageSection extends ConsumerWidget {
  final AppSettings settings;
  const _LanguageSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Bahasa AI', Icons.translate_rounded),
        _sectionCard(
          context: context,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bahasa yang digunakan AI saat membalas',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SegmentedButton<AppLanguage>(
                    segments: const [
                      ButtonSegment(value: AppLanguage.indonesian, label: Text('Indonesia')),
                      ButtonSegment(value: AppLanguage.english, label: Text('English')),
                      ButtonSegment(value: AppLanguage.mixed, label: Text('Campur')),
                    ],
                    selected: {settings.language},
                    onSelectionChanged: (s) {
                      if (s.isNotEmpty) {
                        HapticFeedback.selectionClick();
                        final updated = settings..language = s.first;
                        ref.read(appSettingsProvider.notifier).save(updated);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 120.ms).slideY(begin: 0.04, end: 0);
  }
}

// ── Voice Section ─────────────────────────────────────────────────────────────

class _VoiceSection extends ConsumerWidget {
  final AppSettings settings;
  const _VoiceSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Suara', Icons.record_voice_over_rounded),
        _sectionCard(
          context: context,
          children: [
            SwitchListTile(
              dense: true,
              secondary: const Icon(Icons.volume_up_rounded),
              title: const Text('Aktifkan Text-to-Speech'),
              subtitle: const Text('AI akan membacakan pesannya'),
              value: settings.ttsEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              onChanged: (v) {
                HapticFeedback.selectionClick();
                final updated = settings..ttsEnabled = v;
                ref.read(appSettingsProvider.notifier).save(updated);
              },
            ),
            if (settings.ttsEnabled)
              SwitchListTile(
                dense: true,
                secondary: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Auto-play'),
                subtitle: const Text('Langsung bacakan setiap balasan AI'),
                value: settings.ttsAutoPlay,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  final updated = settings..ttsAutoPlay = v;
                  ref.read(appSettingsProvider.notifier).save(updated);
                },
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 180.ms).slideY(begin: 0.04, end: 0);
  }
}

// ── Notifications Section ─────────────────────────────────────────────────────

class _NotificationsSection extends ConsumerWidget {
  final AppSettings settings;
  const _NotificationsSection({required this.settings});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final parts = settings.notificationMorningTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 7,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Waktu Pesan Pagi',
    );

    if (picked == null || !context.mounted) return;

    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updated = settings..notificationMorningTime = timeStr;
    ref.read(appSettingsProvider.notifier).save(updated);
    await ref.read(notificationProvider.notifier).applySettings(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Notifikasi', Icons.notifications_outlined),
        _sectionCard(
          context: context,
          children: [
            SwitchListTile(
              dense: true,
              secondary: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Pesan Pagi'),
              subtitle: const Text('Sapaan romantis setiap pagi'),
              value: settings.notificationMorningEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              onChanged: (v) async {
                HapticFeedback.selectionClick();
                final updated = settings..notificationMorningEnabled = v;
                ref.read(appSettingsProvider.notifier).save(updated);
                await ref.read(notificationProvider.notifier).applySettings(updated);
              },
            ),
            if (settings.notificationMorningEnabled)
              ListTile(
                dense: true,
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Waktu Pesan Pagi'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings.notificationMorningTime,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
                onTap: () => _pickTime(context, ref),
              ),
            SwitchListTile(
              dense: true,
              secondary: const Icon(Icons.timer_outlined),
              title: const Text('Ingatkan saat tidak aktif'),
              subtitle: const Text('Notifikasi jika >6 jam tidak buka app'),
              value: settings.notificationCheckinEnabled,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              onChanged: (v) async {
                HapticFeedback.selectionClick();
                final updated = settings..notificationCheckinEnabled = v;
                ref.read(appSettingsProvider.notifier).save(updated);
                await ref.read(notificationProvider.notifier).applySettings(updated);
              },
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 240.ms).slideY(begin: 0.04, end: 0);
  }
}

// ── Data & Privacy Section ────────────────────────────────────────────────────

class _DataPrivacySection extends ConsumerWidget {
  const _DataPrivacySection();

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Percakapan?'),
        content: const Text(
          'Semua riwayat chat akan dihapus secara permanen.\n'
          'Aksi ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.heartRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    HapticFeedback.heavyImpact();
    ref.read(objectBoxServiceProvider).messageBox.removeAll();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua percakapan telah dihapus')));
    }
  }

  Future<void> _exportChat(BuildContext context, WidgetRef ref) async {
    final db = ref.read(objectBoxServiceProvider);
    final messages = db.messageBox.getAll()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (messages.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tidak ada percakapan untuk diekspor')));
      }
      return;
    }

    final personas = db.personaBox.getAll();
    final persona = personas.isNotEmpty ? personas.first : null;
    final personaName = (persona?.name.isNotEmpty == true) ? persona!.name : 'AI';
    final userNickname = (persona?.nicknameForUser.isNotEmpty == true)
        ? persona!.nicknameForUser
        : 'Kamu';

    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final fmtShort = DateFormat('dd/MM HH:mm');
    final buffer = StringBuffer()
      ..writeln('VirtualHeart — Ekspor Chat')
      ..writeln('Tanggal ekspor: ${fmt.format(DateTime.now())}')
      ..writeln('Persona: $personaName')
      ..writeln('=' * 40)
      ..writeln();

    for (final msg in messages) {
      final sender = msg.role == MessageRole.user ? userNickname : personaName;
      buffer
        ..writeln('[${fmtShort.format(msg.timestamp)}] $sender:')
        ..writeln(msg.content)
        ..writeln();
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'virtualheart_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString(), flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat diekspor ke: $fileName'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengekspor chat')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Data & Privasi', Icons.lock_outline_rounded),
        _sectionCard(
          context: context,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.storage_rounded, color: AppColors.textSecondary),
              title: const Text('Penyimpanan Lokal'),
              subtitle: const Text(
                'Semua data tersimpan di perangkat ini.\n'
                'Tidak ada data yang dikirim ke server.',
              ),
              isThreeLine: true,
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.heartRed),
              title: const Text(
                'Hapus Semua Percakapan',
                style: TextStyle(color: AppColors.heartRed),
              ),
              onTap: () => _confirmDeleteAll(context, ref),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.download_rounded, color: AppColors.primary),
              title: const Text('Ekspor Chat (.txt)'),
              subtitle: const Text('Simpan riwayat percakapan ke file teks'),
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => _exportChat(context, ref),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.04, end: 0);
  }
}
