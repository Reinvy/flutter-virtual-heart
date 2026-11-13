// Unit test — kontras token warna multi-tema (DESIGN §2, WCAG AA 4.5:1).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/design/app_theme.dart';
import 'package:virtual_heart/core/design/tokens/app_colors.dart';
import 'package:virtual_heart/models/app_settings.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('kontras token >= 4.5:1 di seluruh 8 palet (4 tema × Light/Dark)', () {
    for (final style in AppThemeStyle.values) {
      for (final brightness in Brightness.values) {
        final palette = AppPalettes.resolve(style, brightness);
        final label = '${style.name}/${brightness.name}';

        test('$label pasangan warna utama >= 4.5:1', () {
          final pairs = <String, (Color, Color)>{
            'textPrimary / background': (palette.textPrimary, palette.background),
            'textPrimary / surface': (palette.textPrimary, palette.surface),
            'textSecondary / surface': (palette.textSecondary, palette.surface),
            'textSecondary / background': (
              palette.textSecondary,
              palette.background,
            ),
            'primaryDeep / background': (palette.primaryDeep, palette.background),
            'primaryDeep / surface': (palette.primaryDeep, palette.surface),
            'textOnPrimary / primary': (palette.textOnPrimary, palette.primary),
            'accentDeep / surface': (palette.accentDeep, palette.surface),
            'goldText / surface': (palette.goldText, palette.surface),
            'bubbleUserOn / userBubbleBg': (
              palette.bubbleUserOn,
              palette.userBubbleBg,
            ),
          };

          pairs.forEach((name, pair) {
            expect(
              _contrast(pair.$1, pair.$2),
              greaterThanOrEqualTo(4.5),
              reason: '$label -> $name',
            );
          });
        });

        test('$label ColorScheme onSurfaceVariant / surface >= 4.5:1', () {
          final theme = brightness == Brightness.light
              ? AppTheme.lightFor(style)
              : AppTheme.darkFor(style);
          expect(
            _contrast(
              theme.colorScheme.onSurfaceVariant,
              theme.colorScheme.surface,
            ),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }
  });
}
