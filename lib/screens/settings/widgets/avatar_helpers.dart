import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/persona_config.dart';

// ── Avatar data ───────────────────────────────────────────────────────────────

class AvatarOpt {
  final String id;
  final Color base;
  final Color accent;
  const AvatarOpt({required this.id, required this.base, required this.accent});
}

const girlfriendAvatars = <AvatarOpt>[
  AvatarOpt(id: 'gf_1', base: Color(0xFFC2507A), accent: Color(0xFFE8839F)),
  AvatarOpt(id: 'gf_2', base: Color(0xFF7B5EA7), accent: Color(0xFFA882D4)),
  AvatarOpt(id: 'gf_3', base: Color(0xFFE8506A), accent: Color(0xFFFF8090)),
  AvatarOpt(id: 'gf_4', base: Color(0xFFD4739A), accent: Color(0xFFEEA0C0)),
  AvatarOpt(id: 'gf_5', base: Color(0xFF9B6EBA), accent: Color(0xFFBE99DD)),
  AvatarOpt(id: 'gf_6', base: Color(0xFFC47BAA), accent: Color(0xFFE0A8CA)),
];

const boyfriendAvatars = <AvatarOpt>[
  AvatarOpt(id: 'bf_1', base: Color(0xFF5B8CCC), accent: Color(0xFF88B4E8)),
  AvatarOpt(id: 'bf_2', base: Color(0xFF7B5EA7), accent: Color(0xFFA882D4)),
  AvatarOpt(id: 'bf_3', base: Color(0xFF3D8B6E), accent: Color(0xFF68B095)),
  AvatarOpt(id: 'bf_4', base: Color(0xFF4E7AA0), accent: Color(0xFF7BA8CC)),
  AvatarOpt(id: 'bf_5', base: Color(0xFF6472B5), accent: Color(0xFF8E9CD8)),
  AvatarOpt(id: 'bf_6', base: Color(0xFF5D9E8C), accent: Color(0xFF87C4B5)),
];

const personalityLabels = <PersonalityPreset, String>{
  PersonalityPreset.gentle: 'Lembut 🌸',
  PersonalityPreset.cheerful: 'Ceria ✨',
  PersonalityPreset.mature: 'Dewasa 🌙',
  PersonalityPreset.mysterious: 'Misterius 🔮',
};

const genderLabels = <PersonaGender, String>{
  PersonaGender.girlfriend: 'Girlfriend',
  PersonaGender.boyfriend: 'Boyfriend',
};

// ── Avatar circle widget ──────────────────────────────────────────────────────

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
