import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('RequestScopeInspector.recordRequest', () {
    test('enabled=true on recordRequest - appends to the buffer and emits a '
        'RequestStartedEvent', () async {
      final RequestScopeInspector inspector = RequestScopeInspector();
      final List<RequestScopeEvent> events = <RequestScopeEvent>[];
      final StreamSubscription<RequestScopeEvent> sub = inspector.events.listen(
        events.add,
      );

      inspector.recordRequest(exchangeId: 'x', request: _req);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(inspector.snapshot(), hasLength(1));
      expect(events.single, isA<RequestStartedEvent>());
    });

    test('enabled=false on recordRequest - keeps the buffer empty', () {
      final RequestScopeInspector inspector = RequestScopeInspector(
        config: const RequestScopeConfig(enabled: false),
      );

      inspector.recordRequest(exchangeId: 'y', request: _req);

      expect(inspector.snapshot(), isEmpty);
    });
  });

  group('RequestScopeInspector.recordResponse', () {
    test('recordResponse after recordRequest - transitions to completed', () {
      final RequestScopeInspector inspector = RequestScopeInspector();
      inspector.recordRequest(exchangeId: 'x', request: _req);
      inspector.recordResponse(exchangeId: 'x', response: _resp);

      expect(inspector.snapshot().single.status, ExchangeStatus.completed);
    });

    test('recordResponse for an unknown id - does nothing', () {
      final RequestScopeInspector inspector = RequestScopeInspector();
      inspector.recordResponse(exchangeId: 'missing', response: _resp);

      expect(inspector.snapshot(), isEmpty);
    });

    test('enabled=false on recordResponse - does nothing', () {
      final RequestScopeInspector inspector = RequestScopeInspector(
        config: const RequestScopeConfig(enabled: false),
      );
      inspector.recordResponse(exchangeId: 'x', response: _resp);

      expect(inspector.snapshot(), isEmpty);
    });
  });

  group('RequestScopeInspector.recordError', () {
    test('recordError after recordRequest - transitions to failed', () {
      final RequestScopeInspector inspector = RequestScopeInspector();
      inspector.recordRequest(exchangeId: 'x', request: _req);
      inspector.recordError(exchangeId: 'x', error: _err);

      expect(inspector.snapshot().single.status, ExchangeStatus.failed);
    });

    test('recordError for an unknown id - does nothing', () {
      final RequestScopeInspector inspector = RequestScopeInspector();
      inspector.recordError(exchangeId: 'missing', error: _err);

      expect(inspector.snapshot(), isEmpty);
    });
  });

  group('RequestScopeInspector.clear', () {
    test('clear - empties the buffer and emits a BufferClearedEvent', () async {
      final RequestScopeInspector inspector = RequestScopeInspector();
      inspector.recordRequest(exchangeId: 'x', request: _req);

      final List<RequestScopeEvent> events = <RequestScopeEvent>[];
      final StreamSubscription<RequestScopeEvent> sub = inspector.events.listen(
        events.add,
      );

      inspector.clear();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(inspector.snapshot(), isEmpty);
      expect(events.single, isA<BufferClearedEvent>());
    });
  });

  group('RequestScopeInspector.config setter', () {
    test(
      'shrinking bufferCapacity - trims existing entries to the new limit',
      () {
        final RequestScopeInspector inspector = RequestScopeInspector(
          config: const RequestScopeConfig(bufferCapacity: 5),
        );
        for (int i = 0; i < 5; i++) {
          inspector.recordRequest(exchangeId: '$i', request: _req);
        }
        inspector.config = const RequestScopeConfig(bufferCapacity: 2);

        expect(inspector.snapshot(), hasLength(2));
      },
    );
  });

  group('RequestScopeInspector body trimming', () {
    test('String body exceeding maxBodyBytes - tail is truncated', () {
      final RequestScopeInspector inspector = RequestScopeInspector(
        config: const RequestScopeConfig(maxBodyBytes: 4),
      );
      inspector.recordRequest(
        exchangeId: 'x',
        request: RequestData(
          method: HttpMethod.post,
          url: 'https://example.com/x',
          headers: const <String, String>{},
          queryParameters: const <String, String>{},
          body: 'abcdefghij',
          timestamp: DateTime.utc(2026, 5, 20),
        ),
      );

      final Object? body = inspector.snapshot().single.request.body;
      expect(body, isA<String>());
      expect(body as String, startsWith('abcd'));
      expect(body, contains('[truncated]'));
    });

    test('List<int> body exceeding maxBodyBytes - is replaced with a '
        'truncation metadata map', () {
      final RequestScopeInspector inspector = RequestScopeInspector(
        config: const RequestScopeConfig(maxBodyBytes: 2),
      );
      inspector.recordRequest(
        exchangeId: 'x',
        request: RequestData(
          method: HttpMethod.post,
          url: 'https://example.com/x',
          headers: const <String, String>{},
          queryParameters: const <String, String>{},
          body: <int>[1, 2, 3, 4],
          timestamp: DateTime.utc(2026, 5, 20),
        ),
      );

      final Object? body = inspector.snapshot().single.request.body;
      expect(body, isA<Map<String, Object?>>());
      expect((body as Map<String, Object?>)['_truncated'], isTrue);
      expect(body['originalLength'], 4);
    });

    test('includeBodies=false - body is dropped to null', () {
      final RequestScopeInspector inspector = RequestScopeInspector(
        config: const RequestScopeConfig(includeBodies: false),
      );
      inspector.recordRequest(
        exchangeId: 'x',
        request: RequestData(
          method: HttpMethod.post,
          url: 'https://example.com/x',
          headers: const <String, String>{},
          queryParameters: const <String, String>{},
          body: 'something',
          timestamp: DateTime.utc(2026, 5, 20),
        ),
      );

      expect(inspector.snapshot().single.request.body, isNull);
    });
  });
}

final RequestData _req = RequestData(
  method: HttpMethod.get,
  url: 'https://example.com/x',
  headers: const <String, String>{},
  queryParameters: const <String, String>{},
  timestamp: DateTime.utc(2026, 5, 20),
);

final ResponseData _resp = ResponseData(
  statusCode: 200,
  headers: const <String, String>{},
  timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
  duration: const Duration(milliseconds: 12),
);

final ErrorData _err = ErrorData(
  message: 'boom',
  timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
);
