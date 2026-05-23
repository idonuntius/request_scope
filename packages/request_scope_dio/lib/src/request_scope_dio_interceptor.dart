import 'dart:math';

import 'package:dio/dio.dart';
import 'package:request_scope/request_scope.dart';

const String _exchangeIdKey = 'request_scope.exchangeId';
const String _startTimeKey = 'request_scope.start';

/// Dio v5 interceptor that streams every request, response and error to the
/// request_scope DevTools extension.
///
/// Add the interceptor to a [Dio] instance once during app start-up:
///
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(RequestScopeDioInterceptor());
/// ```
class RequestScopeDioInterceptor extends Interceptor {
  /// Creates a new interceptor.
  ///
  /// By default, events are forwarded to [RequestScopeInspector.instance].
  /// Pass a custom [inspector] for testing or when isolating a Dio instance.
  RequestScopeDioInterceptor({
    RequestScopeInspector? inspector,
    String Function()? idGenerator,
  }) : _inspector = inspector ?? RequestScopeInspector.instance,
       _idGenerator = idGenerator ?? _defaultIdGenerator;

  final RequestScopeInspector _inspector;
  final String Function() _idGenerator;

  static final Random _random = Random();

  static String _defaultIdGenerator() {
    final int now = DateTime.now().microsecondsSinceEpoch;
    // `1 << 32` is 0 on the web because Dart int is 32-bit there. Use a value
    // that is safely representable on both the VM and JS runtimes.
    final int salt = _random.nextInt(0x3FFFFFFF);
    return '${now.toRadixString(36)}-${salt.toRadixString(36)}';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String id = _idGenerator();
    final DateTime startedAt = DateTime.now();
    options.extra[_exchangeIdKey] = id;
    options.extra[_startTimeKey] = startedAt;

    final RequestData snapshot = RequestData(
      method: HttpMethod.parse(options.method),
      url: options.uri.toString(),
      headers: _stringifyMap(options.headers),
      queryParameters: _stringifyMap(options.queryParameters),
      body: _captureBody(options.data),
      contentType: options.contentType,
      timestamp: startedAt,
    );
    _inspector.recordRequest(exchangeId: id, request: snapshot);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final String? id = response.requestOptions.extra[_exchangeIdKey] as String?;
    if (id != null) {
      final DateTime? startedAt =
          response.requestOptions.extra[_startTimeKey] as DateTime?;
      final DateTime now = DateTime.now();
      final ResponseData snapshot = ResponseData(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage,
        headers: _stringifyHeaders(response.headers),
        body: _captureBody(response.data),
        contentType: _contentTypeOf(response.headers),
        timestamp: now,
        duration: startedAt == null ? Duration.zero : now.difference(startedAt),
      );
      _inspector.recordResponse(exchangeId: id, response: snapshot);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final String? id = err.requestOptions.extra[_exchangeIdKey] as String?;
    if (id != null) {
      final DateTime? startedAt =
          err.requestOptions.extra[_startTimeKey] as DateTime?;
      final DateTime now = DateTime.now();
      final Duration? elapsed = startedAt == null
          ? null
          : now.difference(startedAt);

      if (err.response != null) {
        final Response<dynamic> response = err.response!;
        _inspector.recordResponse(
          exchangeId: id,
          response: ResponseData(
            statusCode: response.statusCode ?? 0,
            statusMessage: response.statusMessage,
            headers: _stringifyHeaders(response.headers),
            body: _captureBody(response.data),
            contentType: _contentTypeOf(response.headers),
            timestamp: now,
            duration: elapsed ?? Duration.zero,
          ),
        );
      }

      _inspector.recordError(
        exchangeId: id,
        error: ErrorData(
          message: err.message ?? err.toString(),
          type: err.type.name,
          stackTrace: err.stackTrace.toString(),
          timestamp: now,
          duration: elapsed,
        ),
      );
    }
    handler.next(err);
  }

  static Map<String, String> _stringifyMap(Map<String, dynamic> source) {
    return <String, String>{
      for (final MapEntry<String, dynamic> entry in source.entries)
        entry.key: entry.value?.toString() ?? '',
    };
  }

  static Map<String, String> _stringifyHeaders(Headers headers) {
    final Map<String, String> result = <String, String>{};
    headers.forEach((String key, List<String> values) {
      result[key] = values.join(', ');
    });
    return result;
  }

  static String? _contentTypeOf(Headers headers) {
    final List<String>? values = headers.map[Headers.contentTypeHeader];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.join(', ');
  }

  static Object? _captureBody(Object? body) {
    if (body == null) {
      return null;
    }
    if (body is String || body is num || body is bool) {
      return body;
    }
    if (body is List<int>) {
      return body;
    }
    if (body is Map || body is List) {
      return body;
    }
    if (body is FormData) {
      return <String, Object?>{
        'type': 'FormData',
        'fields': <Map<String, String>>[
          for (final MapEntry<String, String> e in body.fields)
            <String, String>{'name': e.key, 'value': e.value},
        ],
        'files': <Map<String, Object?>>[
          for (final MapEntry<String, MultipartFile> e in body.files)
            <String, Object?>{
              'name': e.key,
              'filename': e.value.filename,
              'length': e.value.length,
              'contentType': e.value.contentType?.toString(),
            },
        ],
      };
    }
    return body.toString();
  }
}
