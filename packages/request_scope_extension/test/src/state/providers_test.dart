import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/state/exchange_store.dart';
import 'package:request_scope_extension/src/state/filters.dart';
import 'package:request_scope_extension/src/state/providers.dart';

void main() {
  group('exchangeStoreProvider', () {
    test('multiple reads - return the same instance', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ExchangeStore a = container.read(exchangeStoreProvider);
      final ExchangeStore b = container.read(exchangeStoreProvider);

      expect(identical(a, b), isTrue);
    });
  });

  group('filterProvider / selectedExchangeIdProvider', () {
    test('initial state - empty filter and null selection', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(filterProvider).methods, isEmpty);
      expect(container.read(filterProvider).search, '');
      expect(container.read(selectedExchangeIdProvider), isNull);
    });
  });

  group('filterExchanges', () {
    test('empty filter - returns the input list unchanged', () {
      final List<HttpExchange> input = <HttpExchange>[
        _exchange('a'),
        _exchange('b'),
      ];
      expect(filterExchanges(input, const FilterState()), same(input));
    });

    test('search query - returns only matching entries', () {
      final List<HttpExchange> input = <HttpExchange>[
        _exchange('apple'),
        _exchange('banana'),
      ];
      final List<HttpExchange> result = filterExchanges(
        input,
        const FilterState(search: 'apple'),
      );

      expect(result.map((HttpExchange e) => e.id), <String>['apple']);
    });
  });

  group('findExchange', () {
    test('id present - returns the matching HttpExchange', () {
      final List<HttpExchange> input = <HttpExchange>[
        _exchange('a'),
        _exchange('b'),
      ];
      expect(findExchange(input, 'b')?.id, 'b');
    });

    test('id is null - returns null', () {
      expect(findExchange(<HttpExchange>[_exchange('a')], null), isNull);
    });

    test('id is not found - returns null', () {
      expect(findExchange(<HttpExchange>[_exchange('a')], 'missing'), isNull);
    });
  });
}

HttpExchange _exchange(String id) {
  return HttpExchange(
    id: id,
    request: RequestData(
      method: HttpMethod.get,
      url: 'https://example.com/$id',
      headers: const <String, String>{},
      queryParameters: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20),
    ),
  );
}
