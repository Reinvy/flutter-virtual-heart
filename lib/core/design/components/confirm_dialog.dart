// Komponen shared — dialog konfirmasi seragam.
//
// Dipakai semua aksi destruktif (hapus percakapan, reset persona, reset
// memory, hapus fact) agar satu bahasa visual & satu perilaku.
import 'package:material_ui/material_ui.dart';

import '../tokens/text_styles.dart';

/// Menampilkan dialog konfirmasi. Kembali `true` bila dikonfirmasi.
///
/// Warna diambil dari `ColorScheme` di dalam builder dialog, sehingga kontras
/// tetap benar di light maupun dark mode.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final confirmColor = destructive ? scheme.error : scheme.primary;
      return AlertDialog(
        title: Text(title, style: AppTextStyles.headingMedium(color: scheme.onSurface)),
        content: Text(
          body,
          style: AppTextStyles.bodyMedium(color: scheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelLabel,
              style: AppTextStyles.button(color: scheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: AppTextStyles.button(color: confirmColor),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
