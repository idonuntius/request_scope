import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope_extension/src/inspector_app.dart';
import 'package:request_scope_extension/src/state/connection_controller.dart';
import 'package:request_scope_extension/src/state/exchange_store.dart';
import 'package:request_scope_extension/src/state/providers.dart';

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
  group('InspectorApp', () {
    testWidgets('rendered - mounts the InspectorScreen', (
      WidgetTester tester,
    ) async {
      final ExchangeStore store = ExchangeStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            exchangeStoreProvider.overrideWithValue(store),
            connectionControllerProvider.overrideWithValue(
              _FakeController(store),
            ),
          ],
          child: const MaterialApp(home: InspectorApp()),
        ),
      );

      expect(find.byType(InspectorApp), findsOneWidget);
    });
  });
}
