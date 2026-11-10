// Settings — baris status izin (mikrofon / notifikasi).
//
// Komponen ini hanya presentasi: pemanggil yang membaca & meminta izin.
import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens/app_colors.dart';
import 'settings_row.dart';

enum SettingsPermissionState { granted, denied, notRequested }

class SettingsPermissionRow extends StatelessWidget {
  const SettingsPermissionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    this.onAction,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final SettingsPermissionState state;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onAction,
      trailing: state == SettingsPermissionState.granted
          ? Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.successFor(context),
            )
          : TextButton(
              onPressed: onAction,
              child: Text(actionLabel ?? ''),
            ),
    );
  }
}
