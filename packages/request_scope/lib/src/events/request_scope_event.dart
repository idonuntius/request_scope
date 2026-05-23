import '../models/error_data.dart';
import '../models/http_exchange.dart';
import '../models/request_data.dart';
import '../models/response_data.dart';

/// Discriminator value for [RequestScopeEvent.kind].
abstract final class RequestScopeEventKind {
  /// A request was issued.
  static const String request = 'request';

  /// A response was received.
  static const String response = 'response';

  /// The request failed.
  static const String error = 'error';

  /// The buffer was cleared.
  static const String clear = 'clear';

  /// A full snapshot is being broadcast.
  static const String snapshot = 'snapshot';
}

/// Event broadcast between the inspector and the DevTools extension.
sealed class RequestScopeEvent {
  /// Creates a new event tagged with [kind].
  const RequestScopeEvent(this.kind);

  /// Discriminator. See [RequestScopeEventKind].
  final String kind;

  /// Serialises the event to a JSON map suitable for transport.
  Map<String, Object?> toJson();

  /// Parses a JSON map into the matching [RequestScopeEvent] subtype.
  static RequestScopeEvent fromJson(Map<String, Object?> json) {
    final String kind = (json['kind'] as String?) ?? '';
    switch (kind) {
      case RequestScopeEventKind.request:
        return RequestStartedEvent(
          exchangeId: (json['exchangeId'] as String?) ?? '',
          request: RequestData.fromJson(
            (json['request'] as Map<String, Object?>?) ?? <String, Object?>{},
          ),
        );
      case RequestScopeEventKind.response:
        return ResponseReceivedEvent(
          exchangeId: (json['exchangeId'] as String?) ?? '',
          response: ResponseData.fromJson(
            (json['response'] as Map<String, Object?>?) ?? <String, Object?>{},
          ),
        );
      case RequestScopeEventKind.error:
        return RequestFailedEvent(
          exchangeId: (json['exchangeId'] as String?) ?? '',
          error: ErrorData.fromJson(
            (json['error'] as Map<String, Object?>?) ?? <String, Object?>{},
          ),
        );
      case RequestScopeEventKind.clear:
        return const BufferClearedEvent();
      case RequestScopeEventKind.snapshot:
        final Object? rawList = json['exchanges'];
        final List<HttpExchange> exchanges = <HttpExchange>[
          if (rawList is List)
            for (final Object? item in rawList)
              if (item is Map<String, Object?>) HttpExchange.fromJson(item),
        ];
        return SnapshotEvent(exchanges: exchanges);
      default:
        throw ArgumentError.value(kind, 'kind', 'Unknown event kind');
    }
  }
}

/// Emitted when a new HTTP request starts.
class RequestStartedEvent extends RequestScopeEvent {
  /// Creates a new [RequestStartedEvent].
  const RequestStartedEvent({required this.exchangeId, required this.request})
    : super(RequestScopeEventKind.request);

  /// Stable identifier for the exchange.
  final String exchangeId;

  /// Outbound request data.
  final RequestData request;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind,
    'exchangeId': exchangeId,
    'request': request.toJson(),
  };
}

/// Emitted when a response is received.
class ResponseReceivedEvent extends RequestScopeEvent {
  /// Creates a new [ResponseReceivedEvent].
  const ResponseReceivedEvent({
    required this.exchangeId,
    required this.response,
  }) : super(RequestScopeEventKind.response);

  /// Stable identifier for the exchange.
  final String exchangeId;

  /// Inbound response data.
  final ResponseData response;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind,
    'exchangeId': exchangeId,
    'response': response.toJson(),
  };
}

/// Emitted when a request fails.
class RequestFailedEvent extends RequestScopeEvent {
  /// Creates a new [RequestFailedEvent].
  const RequestFailedEvent({required this.exchangeId, required this.error})
    : super(RequestScopeEventKind.error);

  /// Stable identifier for the exchange.
  final String exchangeId;

  /// Failure information.
  final ErrorData error;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind,
    'exchangeId': exchangeId,
    'error': error.toJson(),
  };
}

/// Emitted when the inspector buffer is cleared by the user.
class BufferClearedEvent extends RequestScopeEvent {
  /// Creates a new [BufferClearedEvent].
  const BufferClearedEvent() : super(RequestScopeEventKind.clear);

  @override
  Map<String, Object?> toJson() => <String, Object?>{'kind': kind};
}

/// Emitted when the extension requests a full snapshot.
class SnapshotEvent extends RequestScopeEvent {
  /// Creates a new [SnapshotEvent].
  const SnapshotEvent({required this.exchanges})
    : super(RequestScopeEventKind.snapshot);

  /// All exchanges currently held in the inspector buffer.
  final List<HttpExchange> exchanges;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind,
    'exchanges': <Map<String, Object?>>[
      for (final HttpExchange exchange in exchanges) exchange.toJson(),
    ],
  };
}
