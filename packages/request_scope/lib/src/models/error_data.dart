/// Snapshot of a failed HTTP exchange.
class ErrorData {
  /// Creates a new [ErrorData] snapshot.
  const ErrorData({
    required this.message,
    required this.timestamp,
    this.type,
    this.stackTrace,
    this.duration,
  });

  /// Error message.
  final String message;

  /// Runtime type name of the original error, when available.
  final String? type;

  /// Stringified stack trace, when available.
  final String? stackTrace;

  /// Local clock when the error was raised.
  final DateTime timestamp;

  /// Time elapsed between request issue and failure, when measurable.
  final Duration? duration;

  /// Converts the error to a JSON map for transport.
  Map<String, Object?> toJson() => <String, Object?>{
    'message': message,
    'type': type,
    'stackTrace': stackTrace,
    'timestamp': timestamp.toIso8601String(),
    'durationMs': duration == null ? null : duration!.inMicroseconds / 1000.0,
  };

  /// Reconstructs an [ErrorData] from its JSON representation.
  factory ErrorData.fromJson(Map<String, Object?> json) {
    final double? ms = (json['durationMs'] as num?)?.toDouble();
    return ErrorData(
      message: (json['message'] as String?) ?? '',
      type: json['type'] as String?,
      stackTrace: json['stackTrace'] as String?,
      timestamp:
          DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      duration: ms == null ? null : Duration(microseconds: (ms * 1000).round()),
    );
  }
}
