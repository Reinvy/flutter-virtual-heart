// Komponen shared — dialog konfirmasi seragam.
//
// Dipakai semua aksi destruktif (hapus percakapan, reset persona, reset
// memory, hapus fact) agar satu bahasa visual & satu perilaku.
import 'package:material_ui/material_ui.dart';

import '../tokens/app_colors.dart';
import '../tokens/text_styles.dart';

/// Menampilkan dialog konfirmasi. Kembali `true` bila dikonfirmasi.
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
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppTextStyles.headingSmall()),
      content: Text(body, style: AppTextStyles.bodyMedium(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel, style: AppTextStyles.button(color: AppColors.textSecondary)),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: destructive ? AppColors.error : AppColors.primary,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel, style: AppTextStyles.button()),
        ),
      ],
    ),
  );
  return result ?? false;
}
