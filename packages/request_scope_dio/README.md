# request_scope_dio

[![pub package](https://img.shields.io/pub/v/request_scope_dio.svg)](https://pub.dev/packages/request_scope_dio)
[![pub points](https://img.shields.io/pub/points/request_scope_dio.svg)](https://pub.dev/packages/request_scope_dio/score)

[Dio](https://pub.dev/packages/dio) v5 interceptor for
[`request_scope`](https://pub.dev/packages/request_scope) — the Flutter
DevTools Extension that inspects HTTP traffic inside Flutter DevTools.

> `request_scope_dio` does **not** show any UI inside your app. It only
> streams events to the dedicated DevTools tab provided by `request_scope`.

## Features

- 📨 Captures HTTP method, URL, headers, query params, request body,
  response body, status code, duration, timestamp, error and stack trace.
- 🔌 Single interceptor — drop it into any `Dio` instance.
- 🪶 Lightweight — only depends on `dio` and `request_scope`.
- 🚫 Cleanly opt-out in release builds via
  `RequestScopeInspector.instance.config = const RequestScopeConfig(enabled: false)`.

## Screenshots

See the [`request_scope`](https://pub.dev/packages/request_scope) package for
DevTools screenshots.

## Install

```yaml
dependencies:
  dio: ^5.4.0
  request_scope: ^0.1.0
  request_scope_dio: ^0.1.0
```

```bash
flutter pub get
```

## Usage

```dart
import 'package:dio/dio.dart';
import 'package:request_scope_dio/request_scope_dio.dart';

final dio = Dio();
dio.interceptors.add(RequestScopeDioInterceptor());
```

That's it. Run your app, open Flutter DevTools and switch to the
**request_scope** tab — every request issued through this `Dio` instance shows
up live.

### Custom inspector

```dart
final inspector = RequestScopeInspector(
  config: const RequestScopeConfig(bufferCapacity: 1000),
);

dio.interceptors.add(
  RequestScopeDioInterceptor(inspector: inspector),
);
```

### Disable in release

```dart
import 'package:flutter/foundation.dart';

RequestScopeInspector.instance.config = RequestScopeConfig(
  enabled: kDebugMode || kProfileMode,
);
```

## Compatibility

| Tool             | Version                |
| ---------------- | ---------------------- |
| Flutter          | `>=3.19.0`             |
| Dart             | `^3.11.5`              |
| Dio              | `^5.4.0`               |
| request_scope    | `^0.1.0`               |

## Roadmap

The DevTools extension itself is shipped from `request_scope`. Adapter
packages live in the same monorepo. Future adapters planned:

- `package:http`
- Chopper
- WebSocket capture

## License

MIT — see [LICENSE](LICENSE).
