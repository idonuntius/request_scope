<!-- 0xe322 = Material Icon "travel_explore" (network inspector glyph). -->

# request_scope

[![pub package](https://img.shields.io/pub/v/request_scope.svg)](https://pub.dev/packages/request_scope)
[![pub points](https://img.shields.io/pub/points/request_scope.svg)](https://pub.dev/packages/request_scope/score)
[![Flutter](https://img.shields.io/badge/Flutter-stable-blue.svg)](https://flutter.dev)

**request_scope is a Flutter DevTools Extension that inspects HTTP traffic
inside Flutter DevTools.** It is *not* an in-app overlay like Alice or
Chucker — there is no `Overlay`, no `Dialog`, no in-app panel. Requests are
streamed from your app to a dedicated DevTools tab over the VM service.

> This package contains the transport-agnostic core (models, events, inspector
> and DevTools service extension hooks). It also ships the compiled DevTools
> extension UI that DevTools loads automatically as soon as your app depends
> on `request_scope`.
>
> Use one of the adapter packages to capture requests:
>
> - [`request_scope_dio`](https://pub.dev/packages/request_scope_dio) — Dio v5 interceptor.

---

## Features

- 📡 **Live capture** — every request, response and error streamed in real time.
- 🪟 **DevTools native** — renders as a dedicated tab inside Flutter DevTools,
  not on top of your app UI.
- 🧰 **Pluggable** — adapter packages connect any HTTP client; the core is
  client-agnostic.
- 🔍 **Pretty JSON viewer**, method/status filters, free-text search, copy as
  cURL, error highlighting and timing.
- 🌒 **Dark mode** inherited from DevTools.
- 🧱 **Strong types**, Dart 3, null-safe.
- 🚫 **No UI in your app** — production builds can disable the inspector with a
  single config flag.

## Screenshots

<!-- TODO: add screenshots to doc/screenshots and uncomment the `screenshots:`
section in pubspec.yaml. -->

- `doc/screenshots/overview.png` — request list and detail view inside DevTools.
- `doc/screenshots/detail.png` — pretty JSON body viewer with cURL action.

## Install

```yaml
dependencies:
  request_scope: ^0.1.0
  request_scope_dio: ^0.1.0 # if you use Dio
```

```bash
flutter pub get
```

## Usage

```dart
import 'package:flutter/foundation.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_dio/request_scope_dio.dart';
import 'package:dio/dio.dart';

void main() {
  // Disable in release builds.
  RequestScopeInspector.instance.config = const RequestScopeConfig(
    enabled: kDebugMode || kProfileMode,
  );

  final dio = Dio()..interceptors.add(RequestScopeDioInterceptor());

  runApp(MyApp(dio: dio));
}
```

## Opening the DevTools extension

1. Run your app in debug or profile mode (`flutter run`).
2. Press `v` in the terminal to open Flutter DevTools.
3. The **request_scope** tab appears automatically next to *Performance*,
   *Memory*, etc. as long as your app depends on `request_scope`.

> The tab only appears when the connected app declares the dependency.
> Production builds can keep the dependency in `pubspec.yaml`; the inspector
> can still be disabled at runtime via `RequestScopeConfig.enabled`.

## Architecture

```
┌────────────────────────┐     custom events     ┌──────────────────────────┐
│  Flutter App           │ ────────────────────▶ │ Flutter DevTools         │
│                        │   (VM service)        │ ┌──────────────────────┐ │
│  Dio / http / …        │                       │ │ request_scope tab    │ │
│   └─ adapter ──────────┼─────▶ Inspector ──────┤ │  (Flutter web app)   │ │
│       (records events) │      buffer + stream  │ └──────────────────────┘ │
└────────────────────────┘                       └──────────────────────────┘
```

- `request_scope` defines models and the `RequestScopeInspector`. The inspector
  registers `ext.requestScope.*` service extensions and posts custom VM
  service events.
- Adapter packages (`request_scope_dio`, future `_http`, `_chopper`, etc.)
  drive the inspector.
- The DevTools extension UI (a Flutter web app) subscribes to the VM service
  and renders the captured exchanges.

## Compatibility

| Tool             | Version                |
| ---------------- | ---------------------- |
| Flutter          | `>=3.19.0`             |
| Dart             | `^3.11.5`              |
| Dio (adapter)    | `^5.4.0`               |

## Roadmap

- `package:http` adapter
- Chopper adapter
- WebSocket capture
- Riverpod state tracking
- SQLite inspector
- Request replay

## License

MIT — see [LICENSE](LICENSE).
