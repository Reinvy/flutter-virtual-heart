// Komponen shared — AppIconBadge (ikon dalam wadah membulat lembut).
import 'package:material_ui/material_ui.dart';

import '../tokens/app_sizes.dart';

/// Wadah ikon konsisten untuk baris settings, kartu mood, dan daftar fitur.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = AppSizes.iconBadge,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = color ?? scheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: base.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
      ),
      child: Icon(icon, size: size * 0.5, color: base),
    );
  }
}
