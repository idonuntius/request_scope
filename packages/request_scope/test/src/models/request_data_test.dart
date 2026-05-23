import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('RequestData.toJson / fromJson', () {
    test(
      'round-trip with every field set - every field matches the original',
      () {
        final RequestData original = RequestData(
          method: HttpMethod.post,
          url: 'https://example.com/items',
          headers: const <String, String>{'Authorization': 'Bearer abc'},
          queryParameters: const <String, String>{'page': '1'},
          body: const <String, String>{'name': 'pancake'},
          contentType: 'application/json',
          timestamp: DateTime.utc(2026, 5, 20, 12, 30),
        );

        final RequestData decoded = RequestData.fromJson(original.toJson());

        expect(decoded.method, HttpMethod.post);
        expect(decoded.url, original.url);
        expect(decoded.headers, original.headers);
        expect(decoded.queryParameters, original.queryParameters);
        expect(decoded.body, original.body);
        expect(decoded.contentType, original.contentType);
        expect(decoded.timestamp, original.timestamp);
      },
    );

    test('empty JSON - decodes to safe defaults', () {
      final RequestData decoded = RequestData.fromJson(<String, Object?>{});

      expect(decoded.method, HttpMethod.other);
      expect(decoded.url, '');
      expect(decoded.headers, isEmpty);
      expect(decoded.queryParameters, isEmpty);
      expect(decoded.body, isNull);
      expect(decoded.contentType, isNull);
      expect(decoded.timestamp, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('non-String header values - are coerced via toString', () {
      final RequestData decoded = RequestData.fromJson(<String, Object?>{
        'headers': <Object?, Object?>{1: 123, 'x': null},
      });

      expect(decoded.headers, <String, String>{'1': '123', 'x': ''});
    });
  });
}
