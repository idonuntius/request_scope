import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('ExchangeStatus', () {
    test('enum values - exposes pending/completed/failed in order', () {
      expect(ExchangeStatus.values, <ExchangeStatus>[
        ExchangeStatus.pending,
        ExchangeStatus.completed,
        ExchangeStatus.failed,
      ]);
    });
  });
}
