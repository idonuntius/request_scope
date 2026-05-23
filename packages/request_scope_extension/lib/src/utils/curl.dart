import 'dart:convert';

import 'package:request_scope/request_scope.dart';

/// Builds a `curl` command that reproduces the given [request].
String buildCurl(RequestData request) {
  final StringBuffer buffer = StringBuffer('curl');
  buffer
    ..write(' -X ')
    ..write(request.method.wireName);

  request.headers.forEach((String key, String value) {
    buffer
      ..write(' -H ')
      ..write(_quote('$key: $value'));
  });

  final Object? body = request.body;
  if (body != null) {
    String encoded;
    if (body is String) {
      encoded = body;
    } else {
      try {
        encoded = jsonEncode(body);
      } catch (_) {
        encoded = body.toString();
      }
    }
    buffer
      ..write(' --data ')
      ..write(_quote(encoded));
  }

  buffer
    ..write(' ')
    ..write(_quote(request.url));
  return buffer.toString();
}

String _quote(String value) {
  final String escaped = value.replaceAll(r"'", r"'\''");
  return "'$escaped'";
}
