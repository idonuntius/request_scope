import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/state/exchange_store.dart';

void main() {
  group('ExchangeStore.apply', () {
    test('apply request then response - leaves a single completed entry', () {
      final ExchangeStore store = ExchangeStore();
      store.apply(RequestStartedEvent(exchangeId: 'a', request: _req('a')));
      store.apply(ResponseReceivedEvent(exchangeId: 'a', response: _resp(200)));

      expect(store.value, hasLength(1));
      expect(store.value.first.status, ExchangeStatus.completed);
    });

    test('apply request then error - transitions the entry to failed', () {
      final ExchangeStore store = ExchangeStore();
      store.apply(RequestStartedEvent(exchangeId: 'a', request: _req('a')));
      store.apply(RequestFailedEvent(exchangeId: 'a', error: _err));

      expect(store.value.single.status, ExchangeStatus.failed);
    });

    test('response for an unknown id - is ignored', () {
      final ExchangeStore store = ExchangeStore();
      store.apply(ResponseReceivedEvent(exchangeId: 'x', response: _resp(200)));

      expect(store.value, isEmpty);
    });

    test('error for an unknown id - is ignored', () {
      final ExchangeStore store = ExchangeStore();
      store.apply(RequestFailedEvent(exchangeId: 'x', error: _err));

      expect(store.value, isEmpty);
    });

    test('BufferClearedEvent - drops every existing entry', () {
      final ExchangeStore store = ExchangeStore();
      store.apply(RequestStartedEvent(exchangeId: 'a', request: _req('a')));
      store.apply(const BufferClearedEvent());

      expect(store.value, isEmpty);
    });

    test('SnapshotEvent - behaves like replaceAll', () {
      final ExchangeStore store = ExchangeStore();
      store.apply(RequestStartedEvent(exchangeId: 'a', request: _req('a')));
      store.apply(
        SnapshotEvent(
          exchanges: <HttpExchange>[HttpExchange(id: 'b', request: _req('b'))],
        ),
      );

      expect(store.value.map((HttpExchange e) => e.id), <String>['b']);
    });
  });

  group('ExchangeStore.capacity (initial)', () {
    test('push events exceeding capacity - drop the oldest entries first', () {
      final ExchangeStore store = ExchangeStore(capacity: 3);
      for (int i = 0; i < 10; i++) {
        store.apply(
          RequestStartedEvent(exchangeId: 'id-$i', request: _req('$i')),
        );
      }

      expect(store.length, 3);
      expect(store.value.map((HttpExchange e) => e.id).toList(), <String>[
        'id-7',
        'id-8',
        'id-9',
      ]);
    });

    test('snapshot exceeding capacity - drops the oldest entries first', () {
      final ExchangeStore store = ExchangeStore(capacity: 2);
      store.apply(
        SnapshotEvent(
          exchanges: <HttpExchange>[
            for (int i = 0; i < 5; i++)
              HttpExchange(id: 'snap-$i', request: _req('$i')),
          ],
        ),
      );

      expect(store.length, 2);
      expect(store.value.map((HttpExchange e) => e.id), <String>[
        'snap-3',
        'snap-4',
      ]);
    });
  });

  group('ExchangeStore.capacity (mutable)', () {
    test('shrinking capacity - trims existing entries to the new limit', () {
      final ExchangeStore store = ExchangeStore(capacity: 5);
      for (int i = 0; i < 5; i++) {
        store.apply(
          RequestStartedEvent(exchangeId: 'id-$i', request: _req('$i')),
        );
      }
      store.capacity = 2;

      expect(store.length, 2);
    });

    test('setting capacity to the same value - is a no-op', () {
      final ExchangeStore store = ExchangeStore(capacity: 5);
      int notifications = 0;
      store.addListener(() => notifications++);
      store.capacity = 5;

      expect(notifications, 0);
    });
  });

  group('ExchangeStore.clear', () {
    test('clear on an empty store - does not notify listeners', () {
      final ExchangeStore store = ExchangeStore();
      int notifications = 0;
      store.addListener(() => notifications++);

      store.clear();

      expect(notifications, 0);
    });

    test('clear with entries - empties the store and notifies listeners', () {
      final ExchangeStore store = ExchangeStore();
      store.apply(RequestStartedEvent(exchangeId: 'a', request: _req('a')));
      int notifications = 0;
      store.addListener(() => notifications++);

      store.clear();

      expect(store.value, isEmpty);
      expect(notifications, 1);
    });
  });
}

RequestData _req(String suffix) {
  return RequestData(
    method: HttpMethod.get,
    url: 'https://example.com/$suffix',
    headers: const <String, String>{},
    queryParameters: const <String, String>{},
    timestamp: DateTime.utc(2026, 5, 20),
  );
}

ResponseData _resp(int statusCode) {
  return ResponseData(
    statusCode: statusCode,
    headers: const <String, String>{},
    timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
    duration: const Duration(milliseconds: 10),
  );
}

final ErrorData _err = ErrorData(
  message: 'boom',
  timestamp: DateTime.utc(2026, 5, 20),
);
