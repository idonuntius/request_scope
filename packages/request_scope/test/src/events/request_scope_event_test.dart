import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('RequestScopeEvent.fromJson', () {
    test('JSON from RequestStartedEvent - decodes back into the same type', () {
      final RequestStartedEvent original = RequestStartedEvent(
        exchangeId: 'a',
        request: _req,
      );
      final RequestScopeEvent decoded = RequestScopeEvent.fromJson(
        original.toJson(),
      );

      expect(decoded, isA<RequestStartedEvent>());
      expect((decoded as RequestStartedEvent).exchangeId, 'a');
    });

    test(
      'JSON from ResponseReceivedEvent - decodes back into the same type',
      () {
        final ResponseReceivedEvent original = ResponseReceivedEvent(
          exchangeId: 'b',
          response: _resp,
        );
        final RequestScopeEvent decoded = RequestScopeEvent.fromJson(
          original.toJson(),
        );

        expect(decoded, isA<ResponseReceivedEvent>());
        expect((decoded as ResponseReceivedEvent).response.statusCode, 200);
      },
    );

    test('JSON from RequestFailedEvent - decodes back into the same type', () {
      final RequestFailedEvent original = RequestFailedEvent(
        exchangeId: 'c',
        error: _err,
      );
      final RequestScopeEvent decoded = RequestScopeEvent.fromJson(
        original.toJson(),
      );

      expect(decoded, isA<RequestFailedEvent>());
      expect((decoded as RequestFailedEvent).error.message, 'boom');
    });

    test('JSON from BufferClearedEvent - decodes back into the same type', () {
      final RequestScopeEvent decoded = RequestScopeEvent.fromJson(
        const BufferClearedEvent().toJson(),
      );

      expect(decoded, isA<BufferClearedEvent>());
    });

    test('JSON from SnapshotEvent - exchanges list is decoded back', () {
      final SnapshotEvent original = SnapshotEvent(
        exchanges: <HttpExchange>[HttpExchange(id: 'x', request: _req)],
      );
      final RequestScopeEvent decoded = RequestScopeEvent.fromJson(
        original.toJson(),
      );

      expect(decoded, isA<SnapshotEvent>());
      expect((decoded as SnapshotEvent).exchanges.single.id, 'x');
    });

    test('unknown kind - throws ArgumentError', () {
      expect(
        () => RequestScopeEvent.fromJson(<String, Object?>{'kind': 'unknown'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('RequestScopeEventKind', () {
    test('known constants - expose the expected wire strings', () {
      expect(RequestScopeEventKind.request, 'request');
      expect(RequestScopeEventKind.response, 'response');
      expect(RequestScopeEventKind.error, 'error');
      expect(RequestScopeEventKind.clear, 'clear');
      expect(RequestScopeEventKind.snapshot, 'snapshot');
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
  duration: const Duration(milliseconds: 10),
);

final ErrorData _err = ErrorData(
  message: 'boom',
  timestamp: DateTime.utc(2026, 5, 20),
);
