/// Snapshot of an inbound HTTP response.
class ResponseData {
  /// Creates a new [ResponseData] snapshot.
  const ResponseData({
    required this.statusCode,
    required this.headers,
    required this.timestamp,
    required this.duration,
    this.body,
    this.contentType,
    this.statusMessage,
  });

  /// HTTP status code.
  final int statusCode;

  /// Status text returned by the server.
  final String? statusMessage;

  /// Response headers.
  final Map<String, String> headers;

  /// Response body, already serialised to a transport friendly form.
  final Object? body;

  /// Resolved content type, when known.
  final String? contentType;

  /// Local clock when the response completed.
  final DateTime timestamp;

  /// Time elapsed between request issue and response completion.
  final Duration duration;

  /// Converts the response to a JSON map for transport.
  Map<String, Object?> toJson() => <String, Object?>{
    'statusCode': statusCode,
    'statusMessage': statusMessage,
    'headers': headers,
    'body': body,
    'contentType': contentType,
    'timestamp': timestamp.toIso8601String(),
    'durationMs': duration.inMicroseconds / 1000.0,
  };

  /// Reconstructs a [ResponseData] from its JSON representation.
  factory ResponseData.fromJson(Map<String, Object?> json) {
    final Object? raw = json['headers'];
    final Map<String, String> headers = <String, String>{
      if (raw is Map)
        for (final MapEntry<Object?, Object?> entry in raw.entries)
          entry.key.toString(): entry.value?.toString() ?? '',
    };
    final double ms = (json['durationMs'] as num?)?.toDouble() ?? 0.0;
    return ResponseData(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      statusMessage: json['statusMessage'] as String?,
      headers: headers,
      body: json['body'],
      contentType: json['contentType'] as String?,
      timestamp:
          DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      duration: Duration(microseconds: (ms * 1000).round()),
    );
  }
}
