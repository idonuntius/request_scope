# request_scope

> **Flutter DevTools Extension** for inspecting HTTP traffic in real time.
> *Not* an in-app overlay. Renders as a dedicated tab inside Flutter DevTools.

This monorepo contains:

| Package                                  | Description                                                    |
| ---------------------------------------- | -------------------------------------------------------------- |
| [`packages/request_scope`](packages/request_scope) | Core: models, events, inspector and DevTools extension bundle. |
| [`packages/request_scope_dio`](packages/request_scope_dio) | Dio v5 interceptor.                                            |
| [`packages/request_scope_extension`](packages/request_scope_extension) | DevTools extension UI (Flutter web app, not published).        |
| [`example`](example)                     | Example Flutter app demonstrating the inspector.               |

## Quick start

```yaml
dependencies:
  request_scope: ^0.1.0
  request_scope_dio: ^0.1.0
```

```dart
import 'package:dio/dio.dart';
import 'package:request_scope_dio/request_scope_dio.dart';

final dio = Dio()..interceptors.add(RequestScopeDioInterceptor());
```

Run the app in debug mode, open Flutter DevTools and switch to the
**request_scope** tab.

## Repository layout

```
request_scope/
├── pubspec.yaml          # Dart pub workspace (Melos free)
├── analysis_options.yaml
├── Makefile              # dev shortcuts
├── packages/
│   ├── request_scope/             # core
│   ├── request_scope_dio/         # Dio adapter
│   └── request_scope_extension/   # DevTools UI
└── example/                       # demo Flutter app
```

## Development

Workspace commands (run from the repo root):

```bash
make get               # dart pub get for the whole workspace
make analyze           # dart analyze
make test              # flutter test
make extension         # run the DevTools UI standalone (Chrome)
make example           # run the demo app
make build-extension   # compile the DevTools UI into the core package
```

## License

MIT — see [LICENSE](LICENSE).
