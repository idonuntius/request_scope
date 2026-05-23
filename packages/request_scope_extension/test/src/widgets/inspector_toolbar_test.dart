import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/state/connection_controller.dart';
import 'package:request_scope_extension/src/state/exchange_store.dart';
import 'package:request_scope_extension/src/state/providers.dart';
import 'package:request_scope_extension/src/widgets/inspector_toolbar.dart';

/// Fake controller that records actions but does not touch the VM service.
class _FakeController implements ConnectionController {
  _FakeController(this.store);

  int clears = 0;
  int refreshes = 0;

  @override
  final ExchangeStore store;

  @override
  Ref<Object?> get ref => throw UnimplementedError();

  @override
  Future<void> clearRemoteBuffer() async {
    clears++;
  }

  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  void start() {}

  @override
  Future<void> dispose() async {}
}

void main() {
  Future<void> pump(WidgetTester tester, _FakeController controller) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          connectionControllerProvider.overrideWithValue(controller),
        ],
        child: const MaterialApp(home: Scaffold(body: InspectorToolbar())),
      ),
    );
  }

  group('InspectorToolbar', () {
    testWidgets('tapping the refresh icon - invokes controller.refresh', (
      WidgetTester tester,
    ) async {
      final _FakeController controller = _FakeController(ExchangeStore());
      await pump(tester, controller);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(controller.refreshes, 1);
    });

    testWidgets(
      'tapping the clear icon - invokes controller.clearRemoteBuffer',
      (WidgetTester tester) async {
        final _FakeController controller = _FakeController(ExchangeStore());
        await pump(tester, controller);

        await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
        await tester.pump();

        expect(controller.clears, 1);
      },
    );

    testWidgets('typing in the search field - updates filterProvider.search', (
      WidgetTester tester,
    ) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            connectionControllerProvider.overrideWithValue(
              _FakeController(ExchangeStore()),
            ),
          ],
          child: Builder(
            builder: (BuildContext context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(body: InspectorToolbar()),
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'foo');
      await tester.pump();

      expect(container.read(filterProvider).search, 'foo');
    });

    testWidgets('tapping a method chip - updates filterProvider.methods', (
      WidgetTester tester,
    ) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            connectionControllerProvider.overrideWithValue(
              _FakeController(ExchangeStore()),
            ),
          ],
          child: Builder(
            builder: (BuildContext context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(body: InspectorToolbar()),
              );
            },
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'POST'));
      await tester.pump();

      expect(container.read(filterProvider).methods, contains(HttpMethod.post));
    });

    testWidgets('tapping the settings icon - opens the SettingsDialog', (
      WidgetTester tester,
    ) async {
      await pump(tester, _FakeController(ExchangeStore()));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
