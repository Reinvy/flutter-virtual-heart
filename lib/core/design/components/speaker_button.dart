// Komponen shared — SpeakerButton (docs/DESIGN.md §3.3)
import 'package:material_ui/material_ui.dart';

import '../tokens/app_sizes.dart';

/// Tombol play/stop TTS di samping bubble AI (target sentuh 48×48).
class SpeakerButton extends StatelessWidget {
  const SpeakerButton({
    super.key,
    required this.isSpeaking,
    this.onTap,
    this.semanticLabel,
  });

  final bool isSpeaking;
  final VoidCallback? onTap;

  /// Label pembaca layar (mis. "Bacakan pesan").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = semanticLabel;
    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: AppSizes.touchTarget,
          height: AppSizes.touchTarget,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSpeaking ? scheme.primaryContainer : scheme.surfaceContainerLow,
              ),
              child: Icon(
                isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                size: 18,
                color: isSpeaking ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
    if (label == null) return button;
    return Semantics(button: true, label: label, child: button);
  }
}
