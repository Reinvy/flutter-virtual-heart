// Komponen shared — AppIconBadge (ikon dalam bingkai persegi-tumpul hairline).
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
    final base = color ?? scheme.onSurface;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Icon(icon, size: size * 0.5, color: base),
    );
  }
}
