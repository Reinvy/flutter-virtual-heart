// Settings — satu section: header (ikon + label uppercase) + kartu.
import 'package:material_ui/material_ui.dart';

import '../../../core/design/components/section_card.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader(context, title, icon, trailing: trailing),
        sectionCard(context: context, children: children),
      ],
    );
  }
}
