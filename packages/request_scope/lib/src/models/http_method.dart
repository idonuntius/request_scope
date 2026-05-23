/// HTTP methods supported by request_scope.
enum HttpMethod {
  /// GET
  get,

  /// POST
  post,

  /// PUT
  put,

  /// PATCH
  patch,

  /// DELETE
  delete,

  /// HEAD
  head,

  /// OPTIONS
  options,

  /// Method outside of the standard set.
  other;

  /// Parses an HTTP method string into an [HttpMethod]. Returns [other] when
  /// the input does not match a known verb.
  static HttpMethod parse(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.get;
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'PATCH':
        return HttpMethod.patch;
      case 'DELETE':
        return HttpMethod.delete;
      case 'HEAD':
        return HttpMethod.head;
      case 'OPTIONS':
        return HttpMethod.options;
      default:
        return HttpMethod.other;
    }
  }

  /// Uppercase wire representation.
  String get wireName => switch (this) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.patch => 'PATCH',
    HttpMethod.delete => 'DELETE',
    HttpMethod.head => 'HEAD',
    HttpMethod.options => 'OPTIONS',
    HttpMethod.other => 'OTHER',
  };
}
