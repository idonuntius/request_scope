import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/screens/inspector_screen.dart';
import 'package:request_scope_extension/src/state/connection_controller.dart';
import 'package:request_scope_extension/src/state/exchange_store.dart';
import 'package:request_scope_extension/src/state/providers.dart';

/// Fake controller that holds an [ExchangeStore] but does not touch the VM
/// service.
class _FakeController implements ConnectionController {
  _FakeController(this.store);

  @override
  final ExchangeStore store;

  @override
  Ref<Object?> get ref => throw UnimplementedError();

  @override
  Future<void> clearRemoteBuffer() async {}

  @override
  Future<void> refresh() async {}

  @override
  void start() {}

  @override
  Future<void> dispose() async {}
}

void main() {
  Future<void> pump(WidgetTester tester, ExchangeStore store) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          exchangeStoreProvider.overrideWithValue(store),
          connectionControllerProvider.overrideWithValue(
            _FakeController(store),
          ),
        ],
        child: const MaterialApp(home: InspectorScreen()),
      ),
    );
  }

  group('InspectorScreen', () {
    testWidgets('empty store - shows empty-state and detail placeholder', (
      WidgetTester tester,
    ) async {
      await pump(tester, ExchangeStore());

      expect(find.text('Waiting for HTTP traffic…'), findsOneWidget);
      expect(find.text('Select a request'), findsOneWidget);
    });

    testWidgets('exchange in the store - renders a row in the left column', (
      WidgetTester tester,
    ) async {
      final ExchangeStore store = ExchangeStore();
      store.apply(
        RequestStartedEvent(
          exchangeId: 'a',
          request: RequestData(
            method: HttpMethod.get,
            url: 'https://example.com/items',
            headers: const <String, String>{},
            queryParameters: const <String, String>{},
            timestamp: DateTime.utc(2026, 5, 20),
          ),
        ),
      );

      await pump(tester, store);

      expect(find.text('https://example.com/items'), findsOneWidget);
    });

    testWidgets('tapping a row - renders the detail column', (
      WidgetTester tester,
    ) async {
      final ExchangeStore store = ExchangeStore();
      store.apply(
        RequestStartedEvent(
          exchangeId: 'a',
          request: RequestData(
            method: HttpMethod.get,
            url: 'https://example.com/items',
            headers: const <String, String>{},
            queryParameters: const <String, String>{},
            timestamp: DateTime.utc(2026, 5, 20),
          ),
        ),
      );

      await pump(tester, store);
      await tester.tap(find.text('https://example.com/items'));
      await tester.pump();

      expect(find.text('Request'), findsOneWidget);
    });
  });
}
