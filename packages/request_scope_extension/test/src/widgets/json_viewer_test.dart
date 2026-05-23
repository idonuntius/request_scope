import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope_extension/src/widgets/json_viewer.dart';

void main() {
  Future<void> pump(WidgetTester tester, Object? value) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: JsonViewer(value: value)),
      ),
    );
  }

  group('JsonViewer', () {
    testWidgets('Map input - renders the pretty printed JSON', (
      WidgetTester tester,
    ) async {
      await pump(tester, <String, int>{'a': 1});

      expect(find.textContaining('"a": 1'), findsOneWidget);
    });

    testWidgets('JSON-shaped string input - parses and pretty prints', (
      WidgetTester tester,
    ) async {
      await pump(tester, '{"b": 2}');

      expect(find.textContaining('"b": 2'), findsOneWidget);
    });

    testWidgets('plain string input - renders as-is', (
      WidgetTester tester,
    ) async {
      await pump(tester, 'plain message');

      expect(find.text('plain message'), findsOneWidget);
    });

    testWidgets('null input - renders the (empty) placeholder', (
      WidgetTester tester,
    ) async {
      await pump(tester, null);

      expect(find.text('(empty)'), findsOneWidget);
    });

    testWidgets('rendered viewer - exposes a Copy icon', (
      WidgetTester tester,
    ) async {
      await pump(tester, <String, int>{'k': 1});

      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
    });
  });
}
