import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('HttpExchange.status', () {
    test('only error set - returns failed status', () {
      final HttpExchange exchange = HttpExchange(
        id: 'a',
        request: _req,
        error: _err,
      );
      expect(exchange.status, ExchangeStatus.failed);
    });

    test('response set without error - returns completed status', () {
      final HttpExchange exchange = HttpExchange(
        id: 'a',
        request: _req,
        response: _resp,
      );
      expect(exchange.status, ExchangeStatus.completed);
    });

    test('neither response nor error set - returns pending status', () {
      final HttpExchange exchange = HttpExchange(id: 'a', request: _req);
      expect(exchange.status, ExchangeStatus.pending);
    });
  });

  group('HttpExchange.duration', () {
    test('response present - returns the response duration', () {
      final HttpExchange exchange = HttpExchange(
        id: 'a',
        request: _req,
        response: _resp,
      );
      expect(exchange.duration, const Duration(milliseconds: 250));
    });

    test('only error duration set - returns the error duration', () {
      final HttpExchange exchange = HttpExchange(
        id: 'a',
        request: _req,
        error: _err,
      );
      expect(exchange.duration, const Duration(milliseconds: 75));
    });

    test('neither response nor error - returns null', () {
      final HttpExchange exchange = HttpExchange(id: 'a', request: _req);
      expect(exchange.duration, isNull);
    });
  });

  group('HttpExchange.copyWith', () {
    test('replacing response - keeps other fields untouched', () {
      final HttpExchange original = HttpExchange(id: 'a', request: _req);
      final HttpExchange updated = original.copyWith(response: _resp);

      expect(updated.id, 'a');
      expect(updated.request.url, _req.url);
      expect(updated.response, _resp);
      expect(updated.error, isNull);
    });
  });

  group('HttpExchange.toJson / fromJson', () {
    test('round-trip with id/request/response/error - every field matches '
        'the original', () {
      final HttpExchange original = HttpExchange(
        id: 'abc',
        request: _req,
        response: _resp,
        error: _err,
      );

      final HttpExchange decoded = HttpExchange.fromJson(original.toJson());

      expect(decoded.id, 'abc');
      expect(decoded.request.url, _req.url);
      expect(decoded.response?.statusCode, 200);
      expect(decoded.error?.message, _err.message);
    });

    test('empty JSON - decodes every field to safe defaults', () {
      final HttpExchange decoded = HttpExchange.fromJson(<String, Object?>{});

      expect(decoded.id, '');
      expect(decoded.request.method, HttpMethod.other);
      expect(decoded.response, isNull);
      expect(decoded.error, isNull);
    });
  });
}

final RequestData _req = RequestData(
  method: HttpMethod.get,
  url: 'https://example.com/items',
  headers: const <String, String>{},
  queryParameters: const <String, String>{},
  timestamp: DateTime.utc(2026, 5, 20),
);

final ResponseData _resp = ResponseData(
  statusCode: 200,
  headers: const <String, String>{},
  timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
  duration: const Duration(milliseconds: 250),
);

final ErrorData _err = ErrorData(
  message: 'boom',
  type: 'unknown',
  timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
  duration: const Duration(milliseconds: 75),
);
