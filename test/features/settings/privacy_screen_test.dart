// Widget test — kebijakan privasi (FR-19).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/settings/privacy_screen.dart';

Widget _wrap(Widget child, AppStrings strings) {
  return ProviderScope(
    overrides: [appStringsProvider.overrideWith((ref) => strings)],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('menampilkan judul, kebijakan, dan tombol kembali (ID)', (tester) async {
    await tester.pumpWidget(_wrap(const PrivacyScreen(), const IndonesianStrings()));
    await tester.pumpAndSettle();

    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(find.textContaining('hanya di perangkat ini'), findsOneWidget);
    expect(find.textContaining('tidak pernah dikirim'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('menampilkan kebijakan versi Inggris (EN)', (tester) async {
    await tester.pumpWidget(_wrap(const PrivacyScreen(), const EnglishStrings()));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.textContaining('on this device only'), findsOneWidget);
    expect(find.textContaining('not a substitute for professional'), findsOneWidget);
  });
}
