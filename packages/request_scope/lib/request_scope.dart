/// request_scope — Flutter DevTools Extension for inspecting HTTP traffic.
///
/// This library exposes the data model, events and inspector used by adapter
/// packages (e.g. `request_scope_dio`) and by the DevTools extension UI.
///
/// The package is transport agnostic: it does not depend on any HTTP client.
library;

export 'src/events/request_scope_event.dart';
export 'src/inspector/exchange_buffer.dart';
export 'src/inspector/request_scope_inspector.dart';
export 'src/models/error_data.dart';
export 'src/models/exchange_status.dart';
export 'src/models/http_exchange.dart';
export 'src/models/http_method.dart';
export 'src/models/request_data.dart';
export 'src/models/response_data.dart';
export 'src/service/service_keys.dart';
