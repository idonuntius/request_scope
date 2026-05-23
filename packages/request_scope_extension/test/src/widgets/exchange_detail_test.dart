import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/widgets/exchange_detail.dart';

void main() {
  Future<void> pump(WidgetTester tester, HttpExchange? exchange) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExchangeDetail(exchange: exchange)),
      ),
    );
  }

  group('ExchangeDetail', () {
    testWidgets('exchange is null - shows the "Select a request" prompt', (
      WidgetTester tester,
    ) async {
      await pump(tester, null);

      expect(find.text('Select a request'), findsOneWidget);
    });

    testWidgets(
      'completed exchange - renders URL, method, Request and Response '
      'sections',
      (WidgetTester tester) async {
        await pump(tester, _completed());

        expect(find.text('POST'), findsOneWidget);
        expect(find.text('Request'), findsOneWidget);
        expect(find.text('Response'), findsOneWidget);
        expect(find.textContaining('https://example.com/items'), findsWidgets);
      },
    );

    testWidgets('failed exchange - renders the Error section', (
      WidgetTester tester,
    ) async {
      await pump(tester, _failed());

      expect(find.text('Error'), findsOneWidget);
      expect(find.textContaining('Connection refused'), findsWidgets);
    });

    testWidgets(
      'Copy as cURL button - copies the curl command to the clipboard',
      (WidgetTester tester) async {
        String? clipboardText;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              final dynamic args = methodCall.arguments;
              if (args is Map) {
                clipboardText = args['text'] as String?;
              }
            }
            return null;
          },
        );

        await pump(tester, _completed());
        await tester.tap(find.byIcon(Icons.terminal));
        await tester.pump();

        expect(clipboardText, isNotNull);
        expect(clipboardText, contains('curl'));
      },
    );

    testWidgets('Copy full exchange button - copies the formatted dump to the '
        'clipboard', (WidgetTester tester) async {
      String? clipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final dynamic args = methodCall.arguments;
            if (args is Map) {
              clipboardText = args['text'] as String?;
            }
          }
          return null;
        },
      );

      await pump(tester, _completed());
      await tester.tap(find.byIcon(Icons.copy_all_outlined));
      await tester.pump();

      expect(clipboardText, contains('## Request'));
      expect(clipboardText, contains('## Response'));
    });

    testWidgets(
      'pending exchange - shows the "Waiting for response…" message',
      (WidgetTester tester) async {
        await pump(tester, HttpExchange(id: 'p', request: _request()));

        expect(find.text('Waiting for response…'), findsOneWidget);
      },
    );
  });
}

RequestData _request() {
  return RequestData(
    method: HttpMethod.post,
    url: 'https://example.com/items',
    headers: const <String, String>{'Authorization': 'Bearer abc'},
    queryParameters: const <String, String>{'page': '1'},
    body: const <String, String>{'name': 'pancake'},
    timestamp: DateTime.utc(2026, 5, 20),
  );
}

HttpExchange _completed() {
  return HttpExchange(
    id: 'c',
    request: _request(),
    response: ResponseData(
      statusCode: 201,
      headers: const <String, String>{'content-type': 'application/json'},
      body: const <String, int>{'id': 7},
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
      duration: const Duration(milliseconds: 142),
    ),
  );
}

HttpExchange _failed() {
  return HttpExchange(
    id: 'f',
    request: _request(),
    error: ErrorData(
      message: 'Connection refused',
      type: 'connectionError',
      stackTrace: '#0 fake_frame',
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
    ),
  );
}
