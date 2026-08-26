// Katalog avatar — satu sumber kebenaran (konsolidasi 4 palet duplikat).
import 'package:flutter/material.dart';

import '../../core/design/tokens/app_colors.dart';

/// Opsi avatar persona (id + warna dasar/aksen).
class AvatarOpt {
  final String id;
  final Color base;
  final Color accent;
  const AvatarOpt({required this.id, required this.base, required this.accent});
}

const girlfriendAvatars = <AvatarOpt>[
  AvatarOpt(id: 'gf_1', base: Color(0xFFC24D7E), accent: Color(0xFFF28CB0)),
  AvatarOpt(id: 'gf_2', base: Color(0xFF6D4FA8), accent: Color(0xFFB79BE0)),
  AvatarOpt(id: 'gf_3', base: Color(0xFFE8546E), accent: Color(0xFFF8A9C6)),
  AvatarOpt(id: 'gf_4', base: Color(0xFFD4739A), accent: Color(0xFFEEA0C0)),
  AvatarOpt(id: 'gf_5', base: Color(0xFF9B6EBA), accent: Color(0xFFBE99DD)),
  AvatarOpt(id: 'gf_6', base: Color(0xFFC47BAA), accent: Color(0xFFE0A8CA)),
];

const boyfriendAvatars = <AvatarOpt>[
  AvatarOpt(id: 'bf_1', base: Color(0xFF6D4FA8), accent: Color(0xFFA882D4)),
  AvatarOpt(id: 'bf_2', base: Color(0xFF7B5EA7), accent: Color(0xFFA882D4)),
  AvatarOpt(id: 'bf_3', base: Color(0xFF5D4E8C), accent: Color(0xFF8E7CC0)),
  AvatarOpt(id: 'bf_4', base: Color(0xFF4E5A9E), accent: Color(0xFF7B8ACC)),
  AvatarOpt(id: 'bf_5', base: Color(0xFF6472B5), accent: Color(0xFF8E9CD8)),
  AvatarOpt(id: 'bf_6', base: Color(0xFF5E6FA8), accent: Color(0xFF87A0D4)),
];

/// Daftar avatar untuk gender tertentu.
List<AvatarOpt> avatarsFor({required bool isGirlfriend}) =>
    isGirlfriend ? girlfriendAvatars : boyfriendAvatars;

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

/// Lingkaran avatar bergradien dengan inisial/heart.
Widget avatarCircle(AvatarOpt opt, double size, {bool selected = false}) {
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

/// Avatar persona dengan inisial nama (dipakai chat & bubble).
Widget personaAvatar({
  required String? name,
  required String? avatarId,
  double size = 36,
  TextStyle? textStyle,
}) {
  final color = avatarColor(avatarId);
  final initial = (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '♥';
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text(
      initial,
      style: textStyle ??
          TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w600,
          ),
    ),
  );
}
