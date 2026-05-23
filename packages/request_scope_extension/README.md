# request_scope_extension

This is the **DevTools extension Flutter web app** for
[`request_scope`](https://pub.dev/packages/request_scope). It is **not**
published to pub.dev directly — its compiled output is bundled inside
`packages/request_scope/extension/devtools/build/` so DevTools can load it
whenever a connected app depends on `request_scope`.

> **You almost certainly do not need to depend on this package.** Add
> `request_scope` and an adapter (e.g. `request_scope_dio`) to your app
> instead.

## Building the extension

From the workspace root:

```bash
make build-extension
```

This invokes `flutter build web --wasm --pwa-strategy=none --csp --output ../request_scope/extension/devtools/build`
so that the new build is picked up by DevTools the next time it loads the
extension.

## Running the extension in isolation

```bash
make extension
# or
cd packages/request_scope_extension && flutter run -d chrome
```

The `devtools_extensions` package provides a *Simulated DevTools environment*
that lets you exercise the UI without a connected VM service.

## Layout

```
lib/
├── main.dart                       # Entry point. Wraps everything in DevToolsExtension.
└── src/
    ├── inspector_app.dart          # Top widget below DevToolsExtension.
    ├── screens/                    # Inspector screen (2-column layout).
    ├── state/                      # Riverpod providers, store, connection controller.
    ├── utils/                      # cURL renderer, helpers.
    └── widgets/                    # List, detail, toolbar, JSON viewer, status chip.
```

## License

MIT — see [LICENSE](LICENSE).
