import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_dio/request_scope_dio.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._response);

  final ResponseBody Function(RequestOptions options) _response;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _response(options);
  }
}

void main() {
  group('RequestScopeDioInterceptor (default constructor)', () {
    test('created with default arguments - id generation does not throw on '
        'any platform', () async {
      final RequestScopeInspector inspector = RequestScopeInspector();
      final Dio dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => ResponseBody.fromString('{}', 200),
        )
        ..interceptors.add(RequestScopeDioInterceptor(inspector: inspector));

      await dio.get<dynamic>('https://example.com/health');

      expect(inspector.snapshot(), hasLength(1));
      expect(inspector.snapshot().single.id, isNotEmpty);
    });
  });

  group('RequestScopeDioInterceptor.onRequest / onResponse', () {
    test('GET succeeds with 2xx - records a completed exchange in the '
        'inspector', () async {
      final RequestScopeInspector inspector = RequestScopeInspector();
      int counter = 0;
      final Dio dio = Dio()
        ..httpClientAdapter = _FakeAdapter((RequestOptions options) {
          return ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: <String, List<String>>{
              'content-type': <String>['application/json'],
            },
          );
        })
        ..interceptors.add(
          RequestScopeDioInterceptor(
            inspector: inspector,
            idGenerator: () => 'fixed-${counter++}',
          ),
        );

      final Response<dynamic> response = await dio.get<dynamic>(
        'https://example.com/items?page=1',
      );

      expect(response.statusCode, 200);
      final HttpExchange exchange = inspector.snapshot().single;
      expect(exchange.id, 'fixed-0');
      expect(exchange.status, ExchangeStatus.completed);
      expect(exchange.request.method, HttpMethod.get);
      expect(exchange.request.url, 'https://example.com/items?page=1');
      expect(exchange.response?.statusCode, 200);
    });
  });

  group('RequestScopeDioInterceptor.onError', () {
    test('5xx response - records a failed exchange with both response and '
        'error', () async {
      final RequestScopeInspector inspector = RequestScopeInspector();
      final Dio dio = Dio()
        ..httpClientAdapter = _FakeAdapter((RequestOptions options) {
          return ResponseBody.fromString(
            '{"error":"boom"}',
            500,
            headers: <String, List<String>>{
              'content-type': <String>['application/json'],
            },
          );
        })
        ..interceptors.add(
          RequestScopeDioInterceptor(
            inspector: inspector,
            idGenerator: () => 'err-id',
          ),
        );

      await expectLater(
        dio.post<dynamic>(
          'https://example.com/items',
          data: <String, int>{'x': 1},
        ),
        throwsA(isA<DioException>()),
      );

      final HttpExchange exchange = inspector.snapshot().single;
      expect(exchange.status, ExchangeStatus.failed);
      expect(exchange.response?.statusCode, 500);
      expect(exchange.error, isNotNull);
    });

    test(
      'connection error - records the error only, with no response attached',
      () async {
        final RequestScopeInspector inspector = RequestScopeInspector();
        final Dio dio = Dio()
          ..httpClientAdapter = _FakeAdapter((RequestOptions options) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              message: 'no route to host',
            );
          })
          ..interceptors.add(
            RequestScopeDioInterceptor(
              inspector: inspector,
              idGenerator: () => 'net-fail',
            ),
          );

        await expectLater(
          dio.get<dynamic>('https://example.com/x'),
          throwsA(isA<DioException>()),
        );

        final HttpExchange exchange = inspector.snapshot().single;
        expect(exchange.status, ExchangeStatus.failed);
        expect(exchange.response, isNull);
        expect(exchange.error?.type, 'connectionError');
      },
    );
  });

  group('RequestScopeDioInterceptor body capture', () {
    test('FormData payload - is captured as a FormData metadata map', () async {
      final RequestScopeInspector inspector = RequestScopeInspector();
      final Dio dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => ResponseBody.fromString('{}', 200),
        )
        ..interceptors.add(
          RequestScopeDioInterceptor(
            inspector: inspector,
            idGenerator: () => 'fd',
          ),
        );

      final FormData formData = FormData.fromMap(<String, Object>{
        'name': 'pancake',
        'file': MultipartFile.fromString(
          'binary-content',
          filename: 'photo.txt',
        ),
      });

      await dio.post<dynamic>('https://example.com/upload', data: formData);

      final Object? body = inspector.snapshot().single.request.body;
      expect(body, isA<Map<String, Object?>>());
      expect((body as Map<String, Object?>)['type'], 'FormData');
      expect(body['fields'], isA<List<Object?>>());
      expect(body['files'], isA<List<Object?>>());
    });

    test('body of an unsupported type - falls back to toString()', () async {
      final RequestScopeInspector inspector = RequestScopeInspector();
      final Dio dio = Dio()
        ..options = BaseOptions(contentType: 'text/plain')
        ..httpClientAdapter = _FakeAdapter(
          (_) => ResponseBody.fromString('{}', 200),
        )
        ..interceptors.add(
          RequestScopeDioInterceptor(
            inspector: inspector,
            idGenerator: () => 'misc',
          ),
        );

      try {
        await dio.post<dynamic>('https://example.com/misc', data: 42);
      } on DioException catch (_) {
        // Dio's default transformer may reject the value; the interceptor
        // still records the request payload first.
      }

      expect(inspector.snapshot().single.request.body, isNotNull);
    });
  });

  group('RequestScopeDioInterceptor default id generator', () {
    test('consecutive calls - produce different ids', () async {
      final RequestScopeInspector inspector = RequestScopeInspector();
      final Dio dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          (_) => ResponseBody.fromString('{}', 200),
        )
        ..interceptors.add(RequestScopeDioInterceptor(inspector: inspector));

      await dio.get<dynamic>('https://example.com/a');
      await dio.get<dynamic>('https://example.com/b');

      final List<HttpExchange> snapshot = inspector.snapshot();
      expect(snapshot, hasLength(2));
      expect(snapshot.first.id, isNot(equals(snapshot.last.id)));
    });
  });
}
