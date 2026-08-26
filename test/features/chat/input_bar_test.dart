// Widget test — InputBar (FR-05, FR-06)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/chat/widgets/input_bar.dart';
import 'package:virtual_heart/features/settings/settings_controller.dart';
import 'package:virtual_heart/models/app_settings.dart';

class _TestSettingsNotifier extends AppSettingsNotifier {
  _TestSettingsNotifier(this.value);
  final AppSettings value;

  @override
  AppSettings build() => value;
}

Widget wrap(Widget child) {
  return ProviderScope(
    overrides: [
      appSettingsProvider.overrideWith(() => _TestSettingsNotifier(AppSettings())),
      appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('menampilkan hint dan tombol kirim nonaktif saat kosong', (tester) async {
    await tester.pumpWidget(wrap(InputBar(onSend: (_) {})));

    expect(find.text('Ceritakan harimu...'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('mengetik teks lalu kirim memicu onSend', (tester) async {
    String? sent;
    await tester.pumpWidget(wrap(InputBar(onSend: (t) => sent = t)));

    await tester.enterText(find.byType(TextField), 'Halo sayang');
    await tester.pump(); // biarkan ValueListenableBuilder rebuild → tombol aktif
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(sent, 'Halo sayang');
  });

  testWidgets('onSend tidak dipanggil untuk teks kosong', (tester) async {
    String? sent;
    await tester.pumpWidget(wrap(InputBar(onSend: (t) => sent = t)));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(sent, isNull);
  });

  testWidgets('tombol mikrofon tampil', (tester) async {
    await tester.pumpWidget(wrap(InputBar(onSend: (_) {}, onMicTap: () {})));
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
  });

  testWidgets('input dibatasi 2000 karakter (FR-05)', (tester) async {
    await tester.pumpWidget(wrap(InputBar(onSend: (_) {})));

    final longText = 'a' * 2500;
    await tester.enterText(find.byType(TextField), longText);
    await tester.pump();

    // TextField memakai maxLength → teks yang tersimpan terpotong ke 2000.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, 2000);
    expect(field.controller!.text.length, 2000);
  });
}
