// Katalog avatar — palet duotone editorial kontras tinggi (id tetap `gf_1..6` & `bf_1..6`).
import 'package:material_ui/material_ui.dart';

import '../../core/design/tokens/app_colors.dart';
import '../../core/design/tokens/app_durations.dart';
import '../../core/design/tokens/text_styles.dart';

/// Opsi avatar persona (id + warna dasar/aksen + ikon).
class AvatarOpt {
  final String id;
  final Color base;
  final Color accent;
  final IconData icon;
  const AvatarOpt({
    required this.id,
    required this.base,
    required this.accent,
    required this.icon,
  });
}

const girlfriendAvatars = <AvatarOpt>[
  AvatarOpt(
    id: 'gf_1',
    base: Color(0xFF9C3A25), // warm terracotta
    accent: Color(0xFFE7CFC6),
    icon: Icons.favorite_outline_rounded,
  ),
  AvatarOpt(
    id: 'gf_2',
    base: Color(0xFF285843), // deep sage
    accent: Color(0xFFD2E2DA),
    icon: Icons.spa_outlined,
  ),
  AvatarOpt(
    id: 'gf_3',
    base: Color(0xFF8C5B20), // burnished bronze
    accent: Color(0xFFEDE0CC),
    icon: Icons.auto_awesome_outlined,
  ),
  AvatarOpt(
    id: 'gf_4',
    base: Color(0xFF1C314E), // midnight slate
    accent: Color(0xFFD4DFEE),
    icon: Icons.nights_stay_outlined,
  ),
  AvatarOpt(
    id: 'gf_5',
    base: Color(0xFF4B3228), // espresso
    accent: Color(0xFFE8DDD7),
    icon: Icons.wb_sunny_outlined,
  ),
  AvatarOpt(
    id: 'gf_6',
    base: Color(0xFF631728), // muted garnet
    accent: Color(0xFFEBD6DB),
    icon: Icons.water_drop_outlined,
  ),
];

const boyfriendAvatars = <AvatarOpt>[
  AvatarOpt(
    id: 'bf_1',
    base: Color(0xFF1C314E), // midnight slate
    accent: Color(0xFFD4DFEE),
    icon: Icons.shield_outlined,
  ),
  AvatarOpt(
    id: 'bf_2',
    base: Color(0xFF4B3228), // espresso
    accent: Color(0xFFE8DDD7),
    icon: Icons.bolt_outlined,
  ),
  AvatarOpt(
    id: 'bf_3',
    base: Color(0xFF1F4A38), // deep sage
    accent: Color(0xFFD2E2DA),
    icon: Icons.forest_outlined,
  ),
  AvatarOpt(
    id: 'bf_4',
    base: Color(0xFF7A1F33), // garnet
    accent: Color(0xFFEBD6DB),
    icon: Icons.music_note_outlined,
  ),
  AvatarOpt(
    id: 'bf_5',
    base: Color(0xFF8C5B20), // burnished bronze
    accent: Color(0xFFEDE0CC),
    icon: Icons.explore_outlined,
  ),
  AvatarOpt(
    id: 'bf_6',
    base: Color(0xFF2B2D36), // obsidian ink
    accent: Color(0xFFDCE0E8),
    icon: Icons.dark_mode_outlined,
  ),
];

/// Daftar avatar untuk gender tertentu.
List<AvatarOpt> avatarsFor({required bool isGirlfriend}) =>
    isGirlfriend ? girlfriendAvatars : boyfriendAvatars;

/// Opsi avatar berdasarkan id di kedua katalog; fallback avatar pertama.
AvatarOpt avatarOptForId(String? id) {
  for (final list in [girlfriendAvatars, boyfriendAvatars]) {
    for (final opt in list) {
      if (opt.id == id) return opt;
    }
  }
  return girlfriendAvatars.first;
}

/// Warna dasar avatar berdasarkan id; fallback ke primary.
Color avatarColor(String? id) {
  for (final opt in [...girlfriendAvatars, ...boyfriendAvatars]) {
    if (opt.id == id) return opt.base;
  }
  return AppColors.primary;
}

/// Opsi avatar berdasarkan id (dipakai settings/persona section).
AvatarOpt avatarOptFor(String? id, {bool isGirlfriend = true}) {
  final list = avatarsFor(isGirlfriend: isGirlfriend);
  return list.firstWhere((a) => a.id == id, orElse: () => list.first);
}

/// Lingkaran avatar duotone datar dengan bingkai hairline + ring seleksi tegas.
Widget avatarCircle(
  BuildContext context,
  AvatarOpt opt,
  double size, {
  bool selected = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  return AnimatedContainer(
    duration: AppDurations.durationFast,
    curve: AppDurations.curveStandard,
    width: size,
    height: size,
    padding: EdgeInsets.all(selected ? 3 : 2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? scheme.primary : scheme.outlineVariant,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: opt.base,
        border: Border.all(
          color: opt.accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(opt.icon, size: size * 0.36, color: opt.accent),
      ),
    ),
  );
}

/// Avatar persona tonal datar dengan border hairline 1px dan inisial adaptif tema.
Widget personaAvatar(
  BuildContext context, {
  required String? name,
  required String? avatarId,
  double size = 36,
  TextStyle? textStyle,
}) {
  final opt = avatarOptForId(avatarId);
  final scheme = Theme.of(context).colorScheme;
  // Grapheme pertama, bukan code unit: nama beremoji tidak terpotong.
  final initial = (name?.isNotEmpty ?? false)
      ? name!.characters.first.toUpperCase()
      : '♥';

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: opt.base,
      border: Border.all(color: scheme.outlineVariant, width: 1),
    ),
    child: Center(
      child: Text(
        initial,
        style:
            textStyle ??
            AppTextStyles.headingMedium(
              context,
              color: opt.accent,
            ).copyWith(fontSize: size * 0.42, height: 1),
      ),
    ),
  );
}
