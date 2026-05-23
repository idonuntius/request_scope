import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../events/request_scope_event.dart';
import '../models/error_data.dart';
import '../models/http_exchange.dart';
import '../models/request_data.dart';
import '../models/response_data.dart';
import '../service/service_keys.dart';
import 'exchange_buffer.dart';

/// Configuration for [RequestScopeInspector].
class RequestScopeConfig {
  /// Creates a new configuration.
  const RequestScopeConfig({
    this.enabled = true,
    this.bufferCapacity = 500,
    this.includeBodies = true,
    this.maxBodyBytes = 256 * 1024,
  });

  /// When `false`, the inspector silently drops every event.
  ///
  /// Defaults to `true`. Disable in release builds by passing
  /// `enabled: kDebugMode || kProfileMode` from Flutter foundation.
  final bool enabled;

  /// Maximum number of exchanges retained in memory.
  final int bufferCapacity;

  /// When `false`, request and response bodies are not forwarded to DevTools.
  final bool includeBodies;

  /// Maximum size, in bytes, of bodies forwarded to DevTools. Larger payloads
  /// are truncated and tagged with an explanatory marker.
  final int maxBodyBytes;
}

/// Inspector that captures HTTP exchanges and forwards them to the
/// request_scope DevTools extension.
///
/// Adapter packages (such as `request_scope_dio`) drive this class through
/// [recordRequest], [recordResponse] and [recordError]. The inspector takes
/// care of buffering, broadcasting events to a local [Stream] and posting them
/// over the VM service so the DevTools extension can subscribe in real time.
class RequestScopeInspector {
  /// Creates a new inspector instance.
  ///
  /// Most callers should use [RequestScopeInspector.instance] rather than
  /// constructing their own.
  RequestScopeInspector({
    RequestScopeConfig config = const RequestScopeConfig(),
  }) : _config = config,
       _buffer = ExchangeBuffer(capacity: config.bufferCapacity) {
    _registerServiceExtensions();
  }

  /// Default shared inspector used by adapter packages.
  static final RequestScopeInspector instance = RequestScopeInspector();

  /// Service extensions can be registered at most once per isolate.
  static bool _serviceExtensionsRegistered = false;

  /// When non-null, the inspector that owns the service extensions. Used so a
  /// freshly constructed inspector takes over the previous one's role.
  static RequestScopeInspector? _activeInspector;

  RequestScopeConfig _config;
  ExchangeBuffer _buffer;
  final StreamController<RequestScopeEvent> _eventsController =
      StreamController<RequestScopeEvent>.broadcast();

  /// Current configuration.
  RequestScopeConfig get config => _config;

  /// Replaces the active configuration.
  ///
  /// Resizes the in-memory buffer when [RequestScopeConfig.bufferCapacity]
  /// changes.
  set config(RequestScopeConfig value) {
    final bool capacityChanged = value.bufferCapacity != _config.bufferCapacity;
    _config = value;
    if (capacityChanged) {
      final List<HttpExchange> previous = _buffer.snapshot();
      _buffer = ExchangeBuffer(capacity: value.bufferCapacity);
      for (final HttpExchange exchange in previous) {
        _buffer.upsert(exchange);
      }
    }
  }

  /// Broadcast stream of inspector events. Useful for tests or in-process
  /// consumers; the DevTools extension uses the VM service instead.
  Stream<RequestScopeEvent> get events => _eventsController.stream;

  /// Snapshot of currently buffered exchanges.
  List<HttpExchange> snapshot() => _buffer.snapshot();

  /// Records a new outbound request. Returns the [HttpExchange.id] that
  /// adapters must use when later recording the matching response or error.
  String recordRequest({
    required String exchangeId,
    required RequestData request,
  }) {
    if (!_config.enabled) {
      return exchangeId;
    }
    final RequestData trimmed = _trimRequest(request);
    final HttpExchange exchange = HttpExchange(
      id: exchangeId,
      request: trimmed,
    );
    _buffer.upsert(exchange);
    _emit(RequestStartedEvent(exchangeId: exchangeId, request: trimmed));
    return exchangeId;
  }

  /// Records a response for the given [exchangeId].
  void recordResponse({
    required String exchangeId,
    required ResponseData response,
  }) {
    if (!_config.enabled) {
      return;
    }
    final HttpExchange? existing = _buffer.get(exchangeId);
    if (existing == null) {
      return;
    }
    final ResponseData trimmed = _trimResponse(response);
    _buffer.upsert(existing.copyWith(response: trimmed));
    _emit(ResponseReceivedEvent(exchangeId: exchangeId, response: trimmed));
  }

  /// Records an error for the given [exchangeId].
  void recordError({required String exchangeId, required ErrorData error}) {
    if (!_config.enabled) {
      return;
    }
    final HttpExchange? existing = _buffer.get(exchangeId);
    if (existing == null) {
      return;
    }
    _buffer.upsert(existing.copyWith(error: error));
    _emit(RequestFailedEvent(exchangeId: exchangeId, error: error));
  }

  /// Clears the buffer and notifies subscribers.
  void clear() {
    _buffer.clear();
    _emit(const BufferClearedEvent());
  }

  void _emit(RequestScopeEvent event) {
    if (_eventsController.hasListener) {
      _eventsController.add(event);
    }
    _postEvent(event);
  }

  void _postEvent(RequestScopeEvent event) {
    final String streamName = switch (event) {
      RequestStartedEvent() => RequestScopeServiceKeys.requestEvent,
      ResponseReceivedEvent() => RequestScopeServiceKeys.responseEvent,
      RequestFailedEvent() => RequestScopeServiceKeys.errorEvent,
      BufferClearedEvent() => RequestScopeServiceKeys.clearEvent,
      SnapshotEvent() => RequestScopeServiceKeys.requestEvent,
    };
    developer.postEvent(streamName, event.toJson());
  }

  void _registerServiceExtensions() {
    _activeInspector = this;
    if (_serviceExtensionsRegistered) {
      return;
    }
    _serviceExtensionsRegistered = true;
    developer.registerExtension(RequestScopeServiceKeys.getExchangesMethod, (
      String method,
      Map<String, String> parameters,
    ) async {
      final RequestScopeInspector target = _activeInspector ?? this;
      final SnapshotEvent payload = SnapshotEvent(
        exchanges: target._buffer.snapshot(),
      );
      return developer.ServiceExtensionResponse.result(
        jsonEncode(payload.toJson()),
      );
    });
    developer.registerExtension(RequestScopeServiceKeys.clearMethod, (
      String method,
      Map<String, String> parameters,
    ) async {
      (_activeInspector ?? this).clear();
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{'cleared': true}),
      );
    });
    developer.registerExtension(RequestScopeServiceKeys.configMethod, (
      String method,
      Map<String, String> parameters,
    ) async {
      final RequestScopeConfig active = (_activeInspector ?? this)._config;
      return developer.ServiceExtensionResponse.result(
        jsonEncode(<String, Object?>{
          'enabled': active.enabled,
          'bufferCapacity': active.bufferCapacity,
          'includeBodies': active.includeBodies,
          'maxBodyBytes': active.maxBodyBytes,
        }),
      );
    });
  }

  RequestData _trimRequest(RequestData request) {
    if (_config.includeBodies) {
      return RequestData(
        method: request.method,
        url: request.url,
        headers: request.headers,
        queryParameters: request.queryParameters,
        body: _trimBody(request.body),
        contentType: request.contentType,
        timestamp: request.timestamp,
      );
    }
    return RequestData(
      method: request.method,
      url: request.url,
      headers: request.headers,
      queryParameters: request.queryParameters,
      body: null,
      contentType: request.contentType,
      timestamp: request.timestamp,
    );
  }

  ResponseData _trimResponse(ResponseData response) {
    if (_config.includeBodies) {
      return ResponseData(
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        body: _trimBody(response.body),
        contentType: response.contentType,
        timestamp: response.timestamp,
        duration: response.duration,
      );
    }
    return ResponseData(
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      headers: response.headers,
      body: null,
      contentType: response.contentType,
      timestamp: response.timestamp,
      duration: response.duration,
    );
  }

  Object? _trimBody(Object? body) {
    if (body == null) {
      return null;
    }
    final int limit = _config.maxBodyBytes;
    if (body is String) {
      if (body.length <= limit) {
        return body;
      }
      return '${body.substring(0, limit)}…[truncated]';
    }
    if (body is List<int>) {
      if (body.length <= limit) {
        return body;
      }
      return <String, Object?>{
        '_truncated': true,
        'originalLength': body.length,
        'preview': body.sublist(0, limit),
      };
    }
    return body;
  }
}
