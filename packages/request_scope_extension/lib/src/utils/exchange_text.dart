import 'dart:convert';

import 'package:request_scope/request_scope.dart';

/// Builds a plain-text dump of [exchange] suitable for sharing (e.g. pasting
/// into a bug report). Headings use Markdown notation (`#`, `##`) so they
/// stand out without needing indentation; headers are rendered as bullet
/// lists and bodies / stack traces are wrapped in fenced code blocks. Pasted
/// into GitHub, Slack or any markdown-aware renderer the dump becomes a
/// structured document with syntax-highlighted bodies.
String formatExchange(HttpExchange exchange) {
  final StringBuffer buffer = StringBuffer();

  // ── Summary ──────────────────────────────────────────────────────────
  buffer
    ..writeln('${exchange.request.method.wireName} ${exchange.request.url}')
    ..writeln('Status: ${_statusLine(exchange)}')
    ..writeln('Started: ${exchange.request.timestamp.toIso8601String()}');
  final Duration? duration = exchange.duration;
  if (duration != null) {
    buffer.writeln('Duration: ${_formatDuration(duration)}');
  }
  buffer.writeln();

  // ── Request ──────────────────────────────────────────────────────────
  buffer
    ..writeln('## Request')
    ..writeln();
  if (exchange.request.queryParameters.isNotEmpty) {
    buffer
      ..writeln('### Query')
      ..write(_renderKeyValueList(exchange.request.queryParameters))
      ..writeln();
  }
  buffer
    ..writeln('### Headers')
    ..write(_renderKeyValueList(exchange.request.headers))
    ..writeln()
    ..writeln('### Body')
    ..write(_renderBody(exchange.request.body));

  // ── Response ─────────────────────────────────────────────────────────
  final ResponseData? response = exchange.response;
  if (response != null) {
    buffer
      ..writeln()
      ..writeln('## Response')
      ..writeln()
      ..writeln('### Status')
      ..writeln(
        '${response.statusCode}'
        '${response.statusMessage == null ? '' : ' ${response.statusMessage}'}',
      )
      ..writeln()
      ..writeln('### Headers')
      ..write(_renderKeyValueList(response.headers))
      ..writeln()
      ..writeln('### Body')
      ..write(_renderBody(response.body));
  }

  // ── Error ────────────────────────────────────────────────────────────
  final ErrorData? error = exchange.error;
  if (error != null) {
    buffer
      ..writeln()
      ..writeln('## Error')
      ..writeln();
    if (error.type != null) {
      buffer
        ..writeln('### Type')
        ..writeln(error.type)
        ..writeln();
    }
    if (error.message.isNotEmpty) {
      buffer
        ..writeln('### Message')
        ..writeln(error.message)
        ..writeln();
    }
    if (error.stackTrace != null && error.stackTrace!.isNotEmpty) {
      buffer
        ..writeln('### Stack trace')
        ..write(_fence(error.stackTrace!));
    }
  }

  return buffer.toString().trimRight();
}

String _statusLine(HttpExchange exchange) {
  final int? code = exchange.response?.statusCode;
  switch (exchange.status) {
    case ExchangeStatus.pending:
      return 'pending';
    case ExchangeStatus.failed:
      if (code != null && code > 0) {
        return '$code (failed)';
      }
      return 'failed';
    case ExchangeStatus.completed:
      return code?.toString() ?? '—';
  }
}

String _renderKeyValueList(Map<String, String> entries) {
  if (entries.isEmpty) {
    return '_(none)_\n';
  }
  final StringBuffer buffer = StringBuffer();
  for (final MapEntry<String, String> entry in entries.entries) {
    buffer.writeln('- ${entry.key}: ${entry.value}');
  }
  return buffer.toString();
}

String _renderBody(Object? body) {
  if (body == null) {
    return '_(empty)_\n';
  }
  // Detect JSON-like content so the markdown fence can carry a language tag
  // that triggers syntax highlighting on GitHub / Slack / etc.
  if (body is Map || body is List) {
    try {
      return _fence(_encoder.convert(body), language: 'json');
    } catch (_) {
      return _fence(body.toString());
    }
  }
  if (body is String) {
    final String trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return _fence(_encoder.convert(jsonDecode(trimmed)), language: 'json');
      } catch (_) {
        // fall through; treat as plain text
      }
    }
    return _fence(body);
  }
  return _fence(body.toString());
}

/// Wraps [content] in a triple-backtick fenced block.
///
/// If [content] itself contains ```` ``` ```` we widen the fence with extra
/// backticks so the inner content does not break out (this is the same trick
/// CommonMark uses for nested fences).
String _fence(String content, {String? language}) {
  String fence = '```';
  while (content.contains(fence)) {
    fence = '$fence`';
  }
  final String tag = language ?? '';
  return '$fence$tag\n${content.trimRight()}\n$fence\n';
}

String _formatDuration(Duration duration) {
  if (duration.inMilliseconds < 1) {
    return '${duration.inMicroseconds}µs';
  }
  if (duration.inSeconds < 1) {
    return '${duration.inMilliseconds}ms';
  }
  return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
}

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
