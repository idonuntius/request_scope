/// Constants describing the wire protocol used between the app and the
/// DevTools extension.
///
/// The names are intentionally short so they fit comfortably inside the VM
/// service log payload.
abstract final class RequestScopeServiceKeys {
  /// VM service stream id used for posting custom events.
  ///
  /// `developer.postEvent` requires a stream name and `Extension` is the only
  /// stream that DevTools clients receive without registration.
  static const String extensionStreamId = 'Extension';

  /// Service extension method that returns all currently buffered exchanges.
  static const String getExchangesMethod = 'ext.requestScope.getExchanges';

  /// Service extension method that clears the buffer.
  static const String clearMethod = 'ext.requestScope.clear';

  /// Service extension method that returns the inspector configuration.
  static const String configMethod = 'ext.requestScope.config';

  /// Event name used for new request notifications.
  static const String requestEvent = 'request_scope.request';

  /// Event name used for response notifications.
  static const String responseEvent = 'request_scope.response';

  /// Event name used for error notifications.
  static const String errorEvent = 'request_scope.error';

  /// Event name used when the buffer is cleared.
  static const String clearEvent = 'request_scope.clear';
}
