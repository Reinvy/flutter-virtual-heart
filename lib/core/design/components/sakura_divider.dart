// Komponen shared — pemisah dekoratif bertema kelopak sakura.
import 'package:flutter/material.dart';

/// Garis pemisah dengan aksen kelopak di tengah (sakura).
class SakuraDivider extends StatelessWidget {
  const SakuraDivider({super.key, this.height = 24});

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: Divider(color: scheme.outlineVariant, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.favorite_rounded, size: 12, color: scheme.primary.withValues(alpha: 0.6)),
          ),
          Expanded(child: Divider(color: scheme.outlineVariant, thickness: 1)),
        ],
      ),
    );
  }
}
