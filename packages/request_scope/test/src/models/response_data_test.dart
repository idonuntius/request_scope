import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('ResponseData.toJson / fromJson', () {
    test(
      'round-trip with every field set - every field matches the original',
      () {
        final ResponseData original = ResponseData(
          statusCode: 201,
          statusMessage: 'Created',
          headers: const <String, String>{'content-type': 'application/json'},
          body: const <String, int>{'id': 7},
          contentType: 'application/json',
          timestamp: DateTime.utc(2026, 5, 20, 12, 30, 1),
          duration: const Duration(milliseconds: 250),
        );

        final ResponseData decoded = ResponseData.fromJson(original.toJson());

        expect(decoded.statusCode, 201);
        expect(decoded.statusMessage, 'Created');
        expect(decoded.headers, original.headers);
        expect(decoded.body, original.body);
        expect(decoded.contentType, original.contentType);
        expect(decoded.timestamp, original.timestamp);
        expect(decoded.duration, original.duration);
      },
    );

    test('empty JSON - decodes to safe defaults', () {
      final ResponseData decoded = ResponseData.fromJson(<String, Object?>{});

      expect(decoded.statusCode, 0);
      expect(decoded.statusMessage, isNull);
      expect(decoded.headers, isEmpty);
      expect(decoded.body, isNull);
      expect(decoded.contentType, isNull);
      expect(decoded.duration, Duration.zero);
    });
  });
}
