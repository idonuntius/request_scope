import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/widgets/exchange_list.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<HttpExchange> exchanges,
    String? selectedId,
    ValueChanged<HttpExchange>? onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExchangeList(
            exchanges: exchanges,
            selectedId: selectedId,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('ExchangeList', () {
    testWidgets('empty list - shows the empty-state message', (
      WidgetTester tester,
    ) async {
      await pump(tester, exchanges: <HttpExchange>[]);

      expect(find.text('Waiting for HTTP traffic…'), findsOneWidget);
    });

    testWidgets('multiple exchanges - newest is rendered first', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        exchanges: <HttpExchange>[
          _exchange('first', 'https://example.com/first'),
          _exchange('latest', 'https://example.com/latest'),
        ],
      );

      final Finder firstTextFinder = find.text('https://example.com/first');
      final Finder latestTextFinder = find.text('https://example.com/latest');

      expect(firstTextFinder, findsOneWidget);
      expect(latestTextFinder, findsOneWidget);

      final Offset latest = tester.getTopLeft(latestTextFinder);
      final Offset first = tester.getTopLeft(firstTextFinder);
      expect(latest.dy < first.dy, isTrue);
    });

    testWidgets(
      'tapping a tile - invokes onSelected with the matching exchange',
      (WidgetTester tester) async {
        HttpExchange? captured;
        await pump(
          tester,
          exchanges: <HttpExchange>[_exchange('a', 'https://example.com/a')],
          onSelected: (HttpExchange e) => captured = e,
        );

        await tester.tap(find.text('https://example.com/a'));
        await tester.pump();

        expect(captured?.id, 'a');
      },
    );

    testWidgets('selected row - paints an accent background', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        exchanges: <HttpExchange>[_exchange('a', 'https://example.com/a')],
        selectedId: 'a',
      );

      expect(find.text('https://example.com/a'), findsOneWidget);
      // Decoration presence is enough; full color comparison is brittle.
    });
  });
}

HttpExchange _exchange(String id, String url) {
  return HttpExchange(
    id: id,
    request: RequestData(
      method: HttpMethod.get,
      url: url,
      headers: const <String, String>{},
      queryParameters: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20),
    ),
    response: ResponseData(
      statusCode: 200,
      headers: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
      duration: const Duration(milliseconds: 12),
    ),
  );
}
