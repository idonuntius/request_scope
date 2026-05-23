import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/utils/curl.dart';

void main() {
  group('buildCurl', () {
    test('GET without headers or body - produces a minimal curl command', () {
      final String command = buildCurl(_req(HttpMethod.get));

      expect(command, contains('curl -X GET'));
      expect(command, contains("'https://example.com/x'"));
      expect(command, isNot(contains('--data')));
    });

    test('POST with headers and a JSON body - escapes and includes every '
        'element', () {
      final String command = buildCurl(
        _req(
          HttpMethod.post,
          headers: const <String, String>{"X-Trace'1": '123'},
          body: const <String, String>{'hello': 'world'},
        ),
      );

      expect(command, contains('curl -X POST'));
      expect(command, contains("'X-Trace'\\''1: 123'"));
      expect(command, contains('--data'));
      expect(command, contains('hello'));
    });

    test('String body - is escaped and embedded as-is', () {
      final String command = buildCurl(_req(HttpMethod.post, body: 'raw text'));

      expect(command, contains("--data 'raw text'"));
    });

    test('body that cannot be JSON encoded - is embedded via toString()', () {
      final String command = buildCurl(
        _req(HttpMethod.post, body: DateTime.utc(2026, 1, 1)),
      );

      expect(command, contains('2026'));
    });
  });
}

RequestData _req(
  HttpMethod method, {
  Map<String, String> headers = const <String, String>{},
  Object? body,
}) {
  return RequestData(
    method: method,
    url: 'https://example.com/x',
    headers: headers,
    queryParameters: const <String, String>{},
    body: body,
    timestamp: DateTime.utc(2026, 5, 20),
  );
}
