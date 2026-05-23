import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/utils/exchange_text.dart';

void main() {
  group('formatExchange (completed)', () {
    test(
      'completed exchange with request and response - emits every section',
      () {
        final HttpExchange exchange = HttpExchange(
          id: 'x',
          request: RequestData(
            method: HttpMethod.post,
            url: 'https://example.com/items',
            headers: const <String, String>{'Authorization': 'Bearer abc'},
            queryParameters: const <String, String>{'page': '1'},
            body: const <String, String>{'name': 'pancake'},
            timestamp: DateTime.utc(2026, 5, 19, 12, 0),
          ),
          response: ResponseData(
            statusCode: 201,
            statusMessage: 'Created',
            headers: const <String, String>{'content-type': 'application/json'},
            body: const <String, int>{'id': 7},
            timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
            duration: const Duration(milliseconds: 142),
          ),
        );

        final String dump = formatExchange(exchange);

        expect(dump, contains('POST https://example.com/items'));
        expect(dump, contains('Status: 201'));
        expect(dump, contains('Duration: 142ms'));
        expect(dump, contains('## Request'));
        expect(dump, contains('### Headers\n- Authorization: Bearer abc'));
        expect(dump, contains('### Query\n- page: 1'));
        expect(dump, contains('```json\n{\n  "name": "pancake"\n}\n```'));
        expect(dump, contains('## Response'));
        expect(dump, contains('```json\n{\n  "id": 7\n}\n```'));
      },
    );

    test(
      'JSON-shaped string body - is pretty printed inside a json code fence',
      () {
        final HttpExchange exchange = HttpExchange(
          id: 'x',
          request: _req(),
          response: ResponseData(
            statusCode: 200,
            headers: const <String, String>{},
            body: '{"a":1}',
            timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
            duration: const Duration(seconds: 2, milliseconds: 100),
          ),
        );

        final String dump = formatExchange(exchange);

        expect(dump, contains('```json\n{\n  "a": 1\n}\n```'));
        expect(dump, contains('Duration: 2.10s'));
      },
    );

    test('non-JSON string body - is wrapped in a plain (no language tag) '
        'code fence', () {
      final HttpExchange exchange = HttpExchange(
        id: 'x',
        request: _req(),
        response: ResponseData(
          statusCode: 200,
          headers: const <String, String>{},
          body: 'plain text',
          timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
          duration: const Duration(milliseconds: 10),
        ),
      );

      final String dump = formatExchange(exchange);

      expect(dump, contains('```\nplain text\n```'));
    });

    test('body is null - prints the "_(empty)_" placeholder', () {
      final HttpExchange exchange = HttpExchange(
        id: 'x',
        request: _req(),
        response: ResponseData(
          statusCode: 200,
          headers: const <String, String>{},
          timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
          duration: const Duration(milliseconds: 1),
        ),
      );

      final String dump = formatExchange(exchange);

      expect(dump, contains('### Body\n_(empty)_'));
    });

    test('empty headers - prints the "_(none)_" placeholder', () {
      final HttpExchange exchange = HttpExchange(
        id: 'x',
        request: _req(),
        response: ResponseData(
          statusCode: 200,
          headers: const <String, String>{},
          timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
          duration: const Duration(milliseconds: 1),
        ),
      );

      final String dump = formatExchange(exchange);

      expect(dump, contains('### Headers\n_(none)_'));
    });
  });

  group('formatExchange (failed)', () {
    test('error present - includes the Error section', () {
      final HttpExchange exchange = HttpExchange(
        id: 'y',
        request: _req(),
        error: ErrorData(
          message: 'Connection refused',
          type: 'connectionError',
          stackTrace: '#0 fake_frame\n#1 another_frame',
          timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
          duration: const Duration(milliseconds: 50),
        ),
      );

      final String dump = formatExchange(exchange);

      expect(dump, contains('Status: failed'));
      expect(dump, contains('## Error'));
      expect(dump, contains('### Type\nconnectionError'));
      expect(dump, contains('### Message\nConnection refused'));
      expect(
        dump,
        contains('### Stack trace\n```\n#0 fake_frame\n#1 another_frame\n```'),
      );
    });

    test('failed with a status code - prints "<code> (failed)"', () {
      final HttpExchange exchange = HttpExchange(
        id: 'z',
        request: _req(),
        response: ResponseData(
          statusCode: 500,
          headers: const <String, String>{},
          timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
          duration: const Duration(milliseconds: 10),
        ),
        error: ErrorData(
          message: 'server error',
          timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
        ),
      );

      final String dump = formatExchange(exchange);

      expect(dump, contains('Status: 500 (failed)'));
    });
  });

  group('formatExchange (pending)', () {
    test('no response and no error - prints "Status: pending"', () {
      final HttpExchange exchange = HttpExchange(id: 'p', request: _req());

      final String dump = formatExchange(exchange);

      expect(dump, contains('Status: pending'));
      expect(dump, isNot(contains('## Response')));
      expect(dump, isNot(contains('## Error')));
    });
  });

  group('formatExchange (duration formatting)', () {
    test('duration under 1ms - is rendered in µs', () {
      final HttpExchange exchange = HttpExchange(
        id: 'short',
        request: _req(),
        response: ResponseData(
          statusCode: 200,
          headers: const <String, String>{},
          timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
          duration: const Duration(microseconds: 500),
        ),
      );

      expect(formatExchange(exchange), contains('Duration: 500µs'));
    });
  });

  group('formatExchange (fence escaping)', () {
    test('body containing ``` - widens the surrounding fence', () {
      final HttpExchange exchange = HttpExchange(
        id: 'z',
        request: _req(),
        response: ResponseData(
          statusCode: 200,
          headers: const <String, String>{},
          body: 'inline ``` fence',
          timestamp: DateTime.utc(2026, 5, 19, 12, 0, 1),
          duration: const Duration(milliseconds: 1),
        ),
      );

      final String dump = formatExchange(exchange);
      // The outer fence must NOT be exactly three backticks because the body
      // contains that. The implementation widens the fence to 4+ backticks.
      expect(dump, contains('````'));
    });
  });
}

RequestData _req() {
  return RequestData(
    method: HttpMethod.get,
    url: 'https://example.com/x',
    headers: const <String, String>{},
    queryParameters: const <String, String>{},
    timestamp: DateTime.utc(2026, 5, 19, 12, 0),
  );
}
