import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('ExchangeBuffer.upsert', () {
    test('inserts beyond capacity - drops oldest entries first', () {
      final ExchangeBuffer buffer = ExchangeBuffer(capacity: 2);
      buffer.upsert(_exchange('a'));
      buffer.upsert(_exchange('b'));
      buffer.upsert(_exchange('c'));

      expect(buffer.length, 2);
      expect(buffer.get('a'), isNull);
      expect(buffer.get('b'), isNotNull);
      expect(buffer.get('c'), isNotNull);
    });

    test('upsert of an existing id - replaces the value while preserving '
        'insertion order', () {
      final ExchangeBuffer buffer = ExchangeBuffer(capacity: 4);
      buffer.upsert(_exchange('a'));
      buffer.upsert(_exchange('b'));
      buffer.upsert(_exchange('a', urlSuffix: '-v2'));

      expect(buffer.snapshot().map((HttpExchange e) => e.id).toList(), <String>[
        'a',
        'b',
      ]);
      expect(buffer.get('a')?.request.url, 'https://example.com/a-v2');
    });
  });

  group('ExchangeBuffer.snapshot', () {
    test('multiple inserts - returns every entry in insertion order', () {
      final ExchangeBuffer buffer = ExchangeBuffer(capacity: 3);
      buffer.upsert(_exchange('1'));
      buffer.upsert(_exchange('2'));
      buffer.upsert(_exchange('3'));

      expect(buffer.snapshot().map((HttpExchange e) => e.id).toList(), <String>[
        '1',
        '2',
        '3',
      ]);
    });
  });

  group('ExchangeBuffer.clear', () {
    test('after clear - the buffer becomes empty', () {
      final ExchangeBuffer buffer = ExchangeBuffer(capacity: 2);
      buffer.upsert(_exchange('a'));
      buffer.clear();

      expect(buffer.isEmpty, isTrue);
      expect(buffer.length, 0);
    });
  });

  group('ExchangeBuffer constructor', () {
    test('construction with capacity=0 - throws AssertionError', () {
      expect(() => ExchangeBuffer(capacity: 0), throwsA(isA<AssertionError>()));
    });
  });
}

HttpExchange _exchange(String id, {String urlSuffix = ''}) {
  return HttpExchange(
    id: id,
    request: RequestData(
      method: HttpMethod.get,
      url: 'https://example.com/$id$urlSuffix',
      headers: const <String, String>{},
      queryParameters: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20),
    ),
  );
}
