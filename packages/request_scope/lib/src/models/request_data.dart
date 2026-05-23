import 'http_method.dart';

/// Snapshot of an outbound HTTP request.
class RequestData {
  /// Creates a new [RequestData] snapshot.
  const RequestData({
    required this.method,
    required this.url,
    required this.headers,
    required this.queryParameters,
    required this.timestamp,
    this.body,
    this.contentType,
  });

  /// HTTP verb.
  final HttpMethod method;

  /// Absolute URL of the request.
  final String url;

  /// Request headers.
  final Map<String, String> headers;

  /// Parsed query parameters.
  final Map<String, String> queryParameters;

  /// Request payload, already serialised to a transport friendly form.
  final Object? body;

  /// Resolved content type, when known.
  final String? contentType;

  /// Local clock at the moment the request was issued.
  final DateTime timestamp;

  /// Converts the request to a JSON map for transport.
  Map<String, Object?> toJson() => <String, Object?>{
    'method': method.wireName,
    'url': url,
    'headers': headers,
    'queryParameters': queryParameters,
    'body': body,
    'contentType': contentType,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Reconstructs a [RequestData] from its JSON representation.
  factory RequestData.fromJson(Map<String, Object?> json) {
    return RequestData(
      method: HttpMethod.parse((json['method'] as String?) ?? 'OTHER'),
      url: (json['url'] as String?) ?? '',
      headers: _stringMap(json['headers']),
      queryParameters: _stringMap(json['queryParameters']),
      body: json['body'],
      contentType: json['contentType'] as String?,
      timestamp:
          DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

Map<String, String> _stringMap(Object? source) {
  if (source is! Map) {
    return const <String, String>{};
  }
  return <String, String>{
    for (final MapEntry<Object?, Object?> entry in source.entries)
      entry.key.toString(): entry.value?.toString() ?? '',
  };
}
