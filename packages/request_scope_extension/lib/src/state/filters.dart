import 'package:request_scope/request_scope.dart';

/// Status grouping used by the UI status filter.
enum StatusFilter {
  /// All exchanges.
  all,

  /// 2xx responses.
  success,

  /// 3xx responses.
  redirect,

  /// 4xx responses.
  clientError,

  /// 5xx responses.
  serverError,

  /// Exchanges still waiting for a response.
  pending,

  /// Exchanges that ended with an error.
  failed,
}

/// Adds presentation helpers to [StatusFilter].
extension StatusFilterLabel on StatusFilter {
  /// Human readable label.
  String get label => switch (this) {
    StatusFilter.all => 'All',
    StatusFilter.success => '2xx',
    StatusFilter.redirect => '3xx',
    StatusFilter.clientError => '4xx',
    StatusFilter.serverError => '5xx',
    StatusFilter.pending => 'Pending',
    StatusFilter.failed => 'Failed',
  };
}

/// Aggregate filter state applied to the list of exchanges.
class FilterState {
  /// Creates a new filter state.
  const FilterState({
    this.methods = const <HttpMethod>{},
    this.status = StatusFilter.all,
    this.search = '',
  });

  /// Active method filter. Empty means "all methods".
  final Set<HttpMethod> methods;

  /// Active status filter.
  final StatusFilter status;

  /// Free-text search across URL, method and status code.
  final String search;

  /// Whether [exchange] matches the active filter.
  bool matches(HttpExchange exchange) {
    if (methods.isNotEmpty && !methods.contains(exchange.request.method)) {
      return false;
    }
    if (!_matchesStatus(exchange)) {
      return false;
    }
    if (search.isEmpty) {
      return true;
    }
    final String haystack =
        '${exchange.request.method.wireName} ${exchange.request.url} '
                '${exchange.response?.statusCode ?? ''} ${exchange.error?.message ?? ''}'
            .toLowerCase();
    return haystack.contains(search.toLowerCase());
  }

  bool _matchesStatus(HttpExchange exchange) {
    final int? code = exchange.response?.statusCode;
    switch (status) {
      case StatusFilter.all:
        return true;
      case StatusFilter.success:
        return code != null && code >= 200 && code < 300;
      case StatusFilter.redirect:
        return code != null && code >= 300 && code < 400;
      case StatusFilter.clientError:
        return code != null && code >= 400 && code < 500;
      case StatusFilter.serverError:
        return code != null && code >= 500 && code < 600;
      case StatusFilter.pending:
        return exchange.status == ExchangeStatus.pending;
      case StatusFilter.failed:
        return exchange.status == ExchangeStatus.failed;
    }
  }

  /// Returns a copy with the provided overrides applied.
  FilterState copyWith({
    Set<HttpMethod>? methods,
    StatusFilter? status,
    String? search,
  }) {
    return FilterState(
      methods: methods ?? this.methods,
      status: status ?? this.status,
      search: search ?? this.search,
    );
  }
}
