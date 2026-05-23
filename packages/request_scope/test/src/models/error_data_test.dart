import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('ErrorData.toJson / fromJson', () {
    test(
      'round-trip with every field set - every field matches the original',
      () {
        final ErrorData original = ErrorData(
          message: 'Connection refused',
          type: 'connectionError',
          stackTrace: '#0 fake_frame',
          timestamp: DateTime.utc(2026, 5, 20),
          duration: const Duration(milliseconds: 75),
        );

        final ErrorData decoded = ErrorData.fromJson(original.toJson());

        expect(decoded.message, original.message);
        expect(decoded.type, original.type);
        expect(decoded.stackTrace, original.stackTrace);
        expect(decoded.timestamp, original.timestamp);
        expect(decoded.duration, original.duration);
      },
    );

    test('missing durationMs - decodes to null', () {
      final ErrorData decoded = ErrorData.fromJson(<String, Object?>{
        'message': 'unknown',
        'timestamp': DateTime.utc(2026, 5, 20).toIso8601String(),
      });

      expect(decoded.message, 'unknown');
      expect(decoded.duration, isNull);
    });
  });
}
