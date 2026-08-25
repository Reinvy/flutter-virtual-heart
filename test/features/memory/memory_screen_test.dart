// Widget test — MemoryScreen (FR-12): empty state & daftar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/memory/memory_controller.dart';
import 'package:virtual_heart/features/memory/memory_screen.dart';
import 'package:virtual_heart/features/settings/settings_controller.dart';
import 'package:virtual_heart/models/app_settings.dart';
import 'package:virtual_heart/models/memory_fact.dart';

/// Notifier settings statis untuk test.
class _TestSettingsNotifier extends AppSettingsNotifier {
  _TestSettingsNotifier(this.value);
  final AppSettings value;

  @override
  AppSettings build() => value;
}

/// Notifier memory statis untuk test.
class _TestMemoryNotifier extends MemoryFactsNotifier {
  _TestMemoryNotifier(this.value);
  final List<MemoryFact> value;

  @override
  List<MemoryFact> build() => value;
}

Widget wrap({List<MemoryFact> facts = const []}) {
  return ProviderScope(
    overrides: [
      appSettingsProvider.overrideWith(() => _TestSettingsNotifier(AppSettings())),
      appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
      memoryFactsProvider.overrideWith(() => _TestMemoryNotifier(facts)),
    ],
    child: const MaterialApp(home: MemoryScreen()),
  );
}

void main() {
  testWidgets('empty state tampil saat tidak ada fakta', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Memori AI'), findsOneWidget);
    expect(find.text('Belum ada kenangan tersimpan'), findsOneWidget);
  });

  testWidgets('daftar fakta tampil per kategori', (tester) async {
    final facts = [
      MemoryFact(category: MemoryCategory.personal, key: 'warna favorit', value: 'biru'),
      MemoryFact(category: MemoryCategory.event, key: 'ulang tahun', value: '5 Mei'),
    ];
    await tester.pumpWidget(wrap(facts: facts));

    expect(find.text('PERSONAL'), findsOneWidget);
    expect(find.text('warna favorit'), findsOneWidget);
    expect(find.text('PERISTIWA'), findsOneWidget);
    expect(find.text('ulang tahun'), findsOneWidget);
  });
}
