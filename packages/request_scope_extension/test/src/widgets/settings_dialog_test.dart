import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope_extension/src/state/settings.dart';
import 'package:request_scope_extension/src/widgets/settings_dialog.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => SettingsDialog.show(context),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('SettingsDialog', () {
    testWidgets(
      'just opened - the current capacity is pre-filled in the TextField',
      (WidgetTester tester) async {
        await pumpDialog(tester);

        final TextField field = tester.widget<TextField>(
          find.byType(TextField),
        );
        expect(field.controller?.text, kDefaultCapacity.toString());
      },
    );

    testWidgets(
      'out-of-range number then Apply - shows the range error message',
      (WidgetTester tester) async {
        await pumpDialog(tester);

        await tester.enterText(find.byType(TextField), '5');
        await tester.tap(find.text('Apply'));
        await tester.pump();

        expect(
          find.textContaining(
            'Use a value between $kMinCapacity and $kMaxCapacity',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('non-numeric input then Apply - shows "Enter an integer"', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.text('Apply'));
      await tester.pump();

      expect(find.text('Enter an integer'), findsOneWidget);
    });

    testWidgets('valid value then Apply - closes the dialog', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), '500');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tapping Cancel - closes the dialog', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tapping Reset - resets the TextField to kDefaultCapacity', (
      WidgetTester tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), '2000');
      await tester.tap(find.text('Reset'));
      await tester.pump();

      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, kDefaultCapacity.toString());
    });
  });
}
