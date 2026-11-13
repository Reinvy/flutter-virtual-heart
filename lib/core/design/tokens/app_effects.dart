// Design tokens — Garis & Bingkai (docs/DESIGN.md §2.4)
//
// Sistem Atelier memakai permukaan datar dengan border hairline 1px dan
// border seleksi tegas — tanpa gradien berat atau drop shadow.
import 'package:material_ui/material_ui.dart';

import 'app_sizes.dart';

abstract final class AppBorders {
  AppBorders._();

  /// Border hairline standar 1px memakai `outlineVariant`.
  static BorderSide hairline(BuildContext context, {double alpha = 1}) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return BorderSide(
      color: alpha >= 1 ? color : color.withValues(alpha: alpha),
      width: 1,
    );
  }

  /// Border aksen aktif (mis. kartu atau preset tema terpilih).
  static BorderSide accent(BuildContext context, {double width = 1.5}) {
    return BorderSide(
      color: Theme.of(context).colorScheme.primary,
      width: width,
    );
  }

  /// Dekorasi kartu datar dengan border 1px (atau 1.5px saat terpilih).
  static BoxDecoration cardDecoration(
    BuildContext context, {
    double radius = AppSizes.radiusCard,
    bool selected = false,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: color ?? scheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.fromBorderSide(
        selected ? accent(context) : hairline(context),
      ),
    );
  }
}
