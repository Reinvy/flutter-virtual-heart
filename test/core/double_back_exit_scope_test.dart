// Widget test — DoubleBackExitScope: double-back exit, window expiry, & intercept.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:virtual_heart/core/design/components/double_back_exit_scope.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';

void main() {
  testWidgets(
    'tekan back sekali tampilkan SnackBar, tekan kedua dalam jendela keluar',
    (tester) async {
      var currentTime = DateTime(2026, 11, 13, 10, 0, 0);
      var exitCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
          ],
          child: MaterialApp(
            home: DoubleBackExitScope(
              now: () => currentTime,
              onExit: () async {
                exitCount++;
              },
              child: const Scaffold(body: Text('HOME')),
            ),
          ),
        ),
      );

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(exitCount, 0);
      expect(find.text('Tekan sekali lagi untuk keluar'), findsOneWidget);

      currentTime = currentTime.add(const Duration(seconds: 1));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(exitCount, 1);
      expect(find.text('Tekan sekali lagi untuk keluar'), findsNothing);
    },
  );

  testWidgets(
    'jendela keluar kadaluarsa mereset konfirmasi dan meminta back lagi',
    (tester) async {
      var currentTime = DateTime(2026, 11, 13, 10, 0, 0);
      var exitCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStringsProvider.overrideWith((ref) => const EnglishStrings()),
          ],
          child: MaterialApp(
            home: DoubleBackExitScope(
              now: () => currentTime,
              exitWindow: const Duration(seconds: 2),
              onExit: () async {
                exitCount++;
              },
              child: const Scaffold(body: Text('HOME')),
            ),
          ),
        ),
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exitCount, 0);
      expect(find.text('Press back again to exit'), findsOneWidget);

      currentTime = currentTime.add(const Duration(seconds: 3));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exitCount, 0);
      expect(find.text('Press back again to exit'), findsOneWidget);

      currentTime = currentTime.add(const Duration(milliseconds: 500));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(exitCount, 1);
    },
  );

  testWidgets(
    'onBackBlocked=true mencegat back tanpa SnackBar dan mereset jendela keluar',
    (tester) async {
      var currentTime = DateTime(2026, 11, 13, 10, 0, 0);
      var intercept = false;
      var interceptedCount = 0;
      var exitCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
          ],
          child: MaterialApp(
            home: DoubleBackExitScope(
              now: () => currentTime,
              onBackBlocked: () {
                if (!intercept) return false;
                interceptedCount++;
                return true;
              },
              onExit: () async {
                exitCount++;
              },
              child: const Scaffold(body: Text('HOME')),
            ),
          ),
        ),
      );

      // Tekan back pertama mempersenjatai keluar.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Tekan sekali lagi untuk keluar'), findsOneWidget);

      // Intersep (mis. pindah tab/halaman) mereset jendela keluar.
      intercept = true;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(interceptedCount, 1);
      expect(exitCount, 0);
      expect(find.text('Tekan sekali lagi untuk keluar'), findsNothing);

      // Back berikutnya dianggap tekan pertama lagi.
      intercept = false;
      currentTime = currentTime.add(const Duration(milliseconds: 200));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exitCount, 0);
      expect(find.text('Tekan sekali lagi untuk keluar'), findsOneWidget);
    },
  );

  testWidgets('memanggil SystemNavigator.pop bawaan pada tekan kedua', (
    tester,
  ) async {
    var systemPopCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemNavigator.pop') {
            systemPopCalls++;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
        ],
        child: const MaterialApp(
          home: DoubleBackExitScope(child: Scaffold(body: Text('HOME'))),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(systemPopCalls, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(systemPopCalls, 1);
  });

  testWidgets('canPop=true meneruskan pop normal tanpa SnackBar atau onExit', (
    tester,
  ) async {
    var exitCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStringsProvider.overrideWith((ref) => const IndonesianStrings()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DoubleBackExitScope(
                        canPop: true,
                        onExit: () async {
                          exitCount++;
                        },
                        child: const Scaffold(body: Text('PUSHED')),
                      ),
                    ),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('PUSHED'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('Tekan sekali lagi untuk keluar'), findsNothing);
    expect(exitCount, 0);
  });
}
