# request_scope example

Minimal Flutter app that wires
[`request_scope`](../packages/request_scope) and
[`request_scope_dio`](../packages/request_scope_dio) so you can play with the
DevTools extension immediately.

## Run

```bash
make example
# or
cd example && flutter run
```

Then open Flutter DevTools (press `v` in the `flutter run` terminal) and
switch to the **request_scope** tab.

Tap the buttons to issue sample requests:

- `GET /posts`
- `POST /posts`
- `PUT /posts/1`
- `DELETE /posts/1`
- `Trigger 404`

Each call appears live in the DevTools tab.
