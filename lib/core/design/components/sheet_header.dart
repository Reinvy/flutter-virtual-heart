// Komponen shared — header sheet konsisten (handle + judul + tombol tutup).
import 'package:material_ui/material_ui.dart';

import '../tokens/app_sizes.dart';
import '../tokens/text_styles.dart';
import 'app_icon_button.dart';

/// Handle kecil di puncak sheet.
Widget appSheetHandle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Center(
    child: Container(
      width: 32,
      height: 3,
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
    ),
  );
}

/// Baris judul sheet: judul kiri, tombol tutup kanan.
Widget appSheetHeader(
  BuildContext context, {
  required String title,
  required VoidCallback onClose,
  String? closeTooltip,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.spaceMd + 4,
      vertical: AppSizes.spaceSm,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headingSmall(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppIconButton(
          icon: Icons.close_rounded,
          onPressed: onClose,
          tooltip: closeTooltip,
          bordered: true,
        ),
      ],
    ),
  );
}
