// Katalog avatar — satu sumber kebenaran (konsolidasi 4 palet duplikat).
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design/tokens/app_colors.dart';

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
    base: Color(0xFFC24D7E),
    accent: Color(0xFFF28CB0),
    icon: Icons.favorite_rounded,
  ),
  AvatarOpt(
    id: 'gf_2',
    base: Color(0xFF6D4FA8),
    accent: Color(0xFFB79BE0),
    icon: Icons.local_florist_rounded,
  ),
  AvatarOpt(
    id: 'gf_3',
    base: Color(0xFFE8546E),
    accent: Color(0xFFF8A9C6),
    icon: Icons.auto_awesome_rounded,
  ),
  AvatarOpt(
    id: 'gf_4',
    base: Color(0xFFD4739A),
    accent: Color(0xFFEEA0C0),
    icon: Icons.nights_stay_rounded,
  ),
  AvatarOpt(
    id: 'gf_5',
    base: Color(0xFF9B6EBA),
    accent: Color(0xFFBE99DD),
    icon: Icons.wb_sunny_rounded,
  ),
  AvatarOpt(
    id: 'gf_6',
    base: Color(0xFFC47BAA),
    accent: Color(0xFFE0A8CA),
    icon: Icons.water_drop_rounded,
  ),
];

const boyfriendAvatars = <AvatarOpt>[
  AvatarOpt(
    id: 'bf_1',
    base: Color(0xFF6D4FA8),
    accent: Color(0xFFA882D4),
    icon: Icons.shield_moon_rounded,
  ),
  AvatarOpt(
    id: 'bf_2',
    base: Color(0xFF7B5EA7),
    accent: Color(0xFFA882D4),
    icon: Icons.bolt_rounded,
  ),
  AvatarOpt(
    id: 'bf_3',
    base: Color(0xFF5D4E8C),
    accent: Color(0xFF8E7CC0),
    icon: Icons.forest_rounded,
  ),
  AvatarOpt(
    id: 'bf_4',
    base: Color(0xFF4E5A9E),
    accent: Color(0xFF7B8ACC),
    icon: Icons.music_note_rounded,
  ),
  AvatarOpt(
    id: 'bf_5',
    base: Color(0xFF6472B5),
    accent: Color(0xFF8E9CD8),
    icon: Icons.explore_rounded,
  ),
  AvatarOpt(
    id: 'bf_6',
    base: Color(0xFF5E6FA8),
    accent: Color(0xFF87A0D4),
    icon: Icons.dark_mode_rounded,
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

/// Lingkaran avatar bergradien dengan ikon putih + ring seleksi.
Widget avatarCircle(
  BuildContext context,
  AvatarOpt opt,
  double size, {
  bool selected = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  return AnimatedContainer(
    duration: const Duration(milliseconds: 140),
    curve: Curves.easeOutCubic,
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [opt.accent, opt.base]),
      border: Border.all(
        color: selected ? scheme.primary : Colors.transparent,
        width: 2.5,
      ),
      boxShadow: [
        BoxShadow(
          color: opt.base.withValues(alpha: selected ? 0.45 : 0.35),
          blurRadius: selected ? 16 : 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipOval(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: size * 0.12,
            top: size * 0.10,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Center(child: Icon(opt.icon, size: size * 0.34, color: Colors.white)),
        ],
      ),
    ),
  );
}

/// Avatar persona dengan inisial nama (dipakai chat & bubble).
Widget personaAvatar({
  required String? name,
  required String? avatarId,
  double size = 36,
  TextStyle? textStyle,
}) {
  final opt = avatarOptForId(avatarId);
  // Grapheme pertama, bukan code unit: nama beremoji tidak terpotong.
  final initial = (name?.isNotEmpty ?? false) ? name!.characters.first.toUpperCase() : '♥';
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [opt.accent, opt.base]),
    ),
    child: ClipOval(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: size * 0.12,
            top: size * 0.10,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          Center(
            child: Text(
              initial,
              style:
                  textStyle ??
                  GoogleFonts.fraunces(
                    color: Colors.white,
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}
