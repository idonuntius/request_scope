import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/widgets/status_chip.dart';

void main() {
  Future<void> pump(WidgetTester tester, HttpExchange exchange) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StatusChip(exchange: exchange)),
      ),
    );
  }

  group('StatusChip', () {
    testWidgets('pending exchange - shows a spinner and a "pending" label', (
      WidgetTester tester,
    ) async {
      await pump(tester, HttpExchange(id: 'p', request: _req()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('pending'), findsOneWidget);
    });

    testWidgets('response with 200 - shows "200"', (WidgetTester tester) async {
      await pump(tester, _completed(200));
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('failed with statusCode=500 - shows "500"', (
      WidgetTester tester,
    ) async {
      await pump(tester, _failedWithResponse(500));
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('failed without a status code - shows "ERR"', (
      WidgetTester tester,
    ) async {
      await pump(tester, _failedNoResponse());
      expect(find.text('ERR'), findsOneWidget);
    });
  });
}

RequestData _req() {
  return RequestData(
    method: HttpMethod.get,
    url: 'https://example.com/x',
    headers: const <String, String>{},
    queryParameters: const <String, String>{},
    timestamp: DateTime.utc(2026, 5, 20),
  );
}

HttpExchange _completed(int code) {
  return HttpExchange(
    id: 'c',
    request: _req(),
    response: ResponseData(
      statusCode: code,
      headers: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
      duration: const Duration(milliseconds: 5),
    ),
  );
}

HttpExchange _failedWithResponse(int code) {
  return HttpExchange(
    id: 'f',
    request: _req(),
    response: ResponseData(
      statusCode: code,
      headers: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
      duration: const Duration(milliseconds: 5),
    ),
    error: ErrorData(
      message: 'boom',
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
    ),
  );
}

HttpExchange _failedNoResponse() {
  return HttpExchange(
    id: 'fn',
    request: _req(),
    error: ErrorData(
      message: 'boom',
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
    ),
  );
}
