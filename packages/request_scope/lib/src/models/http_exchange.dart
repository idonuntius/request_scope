import 'error_data.dart';
import 'exchange_status.dart';
import 'request_data.dart';
import 'response_data.dart';

/// Aggregated request/response pair, identified by a stable [id].
class HttpExchange {
  /// Creates a new [HttpExchange].
  const HttpExchange({
    required this.id,
    required this.request,
    this.response,
    this.error,
  });

  /// Stable identifier shared between the request, the response and the error
  /// halves of the same exchange.
  final String id;

  /// Outbound request snapshot.
  final RequestData request;

  /// Inbound response snapshot, when the call completed successfully.
  final ResponseData? response;

  /// Error snapshot, when the call failed.
  final ErrorData? error;

  /// Resolves the exchange lifecycle status.
  ExchangeStatus get status {
    if (error != null) {
      return ExchangeStatus.failed;
    }
    if (response != null) {
      return ExchangeStatus.completed;
    }
    return ExchangeStatus.pending;
  }

  /// Time elapsed for the exchange, when known.
  Duration? get duration => error?.duration ?? response?.duration;

  /// Returns a copy with the provided overrides applied.
  HttpExchange copyWith({
    RequestData? request,
    ResponseData? response,
    ErrorData? error,
  }) {
    return HttpExchange(
      id: id,
      request: request ?? this.request,
      response: response ?? this.response,
      error: error ?? this.error,
    );
  }

  /// JSON representation used for DevTools transport.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'request': request.toJson(),
    'response': response?.toJson(),
    'error': error?.toJson(),
  };

  /// Reconstructs an [HttpExchange] from its JSON representation.
  factory HttpExchange.fromJson(Map<String, Object?> json) {
    final Object? rawRequest = json['request'];
    final Object? rawResponse = json['response'];
    final Object? rawError = json['error'];
    return HttpExchange(
      id: (json['id'] as String?) ?? '',
      request: rawRequest is Map<String, Object?>
          ? RequestData.fromJson(rawRequest)
          : RequestData.fromJson(<String, Object?>{}),
      response: rawResponse is Map<String, Object?>
          ? ResponseData.fromJson(rawResponse)
          : null,
      error: rawError is Map<String, Object?>
          ? ErrorData.fromJson(rawError)
          : null,
    );
  }
}
