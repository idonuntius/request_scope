import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('HttpMethod.parse', () {
    test(
      'lowercase input - normalizes and returns the matching enum value',
      () {
        expect(HttpMethod.parse('get'), HttpMethod.get);
        expect(HttpMethod.parse('post'), HttpMethod.post);
        expect(HttpMethod.parse('put'), HttpMethod.put);
        expect(HttpMethod.parse('patch'), HttpMethod.patch);
        expect(HttpMethod.parse('delete'), HttpMethod.delete);
        expect(HttpMethod.parse('head'), HttpMethod.head);
        expect(HttpMethod.parse('options'), HttpMethod.options);
      },
    );

    test('unknown method name - returns HttpMethod.other', () {
      expect(HttpMethod.parse('TRACE'), HttpMethod.other);
      expect(HttpMethod.parse(''), HttpMethod.other);
    });
  });

  group('HttpMethod.wireName', () {
    test('each enum value - exposes the uppercase HTTP method name', () {
      expect(HttpMethod.get.wireName, 'GET');
      expect(HttpMethod.post.wireName, 'POST');
      expect(HttpMethod.put.wireName, 'PUT');
      expect(HttpMethod.patch.wireName, 'PATCH');
      expect(HttpMethod.delete.wireName, 'DELETE');
      expect(HttpMethod.head.wireName, 'HEAD');
      expect(HttpMethod.options.wireName, 'OPTIONS');
      expect(HttpMethod.other.wireName, 'OTHER');
    });
  });
}
