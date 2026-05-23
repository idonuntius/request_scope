import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:request_scope/request_scope.dart';

import 'exchange_store.dart';
import 'filters.dart';

/// Singleton store backing every list of exchanges in the extension.
final Provider<ExchangeStore> exchangeStoreProvider = Provider<ExchangeStore>((
  Ref ref,
) {
  final ExchangeStore store = ExchangeStore();
  ref.onDispose(store.dispose);
  return store;
});

/// Active filter state.
final StateProvider<FilterState> filterProvider = StateProvider<FilterState>(
  (Ref ref) => const FilterState(),
);

/// Currently selected exchange id, when any.
final StateProvider<String?> selectedExchangeIdProvider =
    StateProvider<String?>((Ref ref) => null);

/// Filters [all] using the active [FilterState].
List<HttpExchange> filterExchanges(List<HttpExchange> all, FilterState filter) {
  if (filter.methods.isEmpty &&
      filter.status == StatusFilter.all &&
      filter.search.isEmpty) {
    return all;
  }
  return all.where(filter.matches).toList(growable: false);
}

/// Returns the exchange with [id] from [all], when found.
HttpExchange? findExchange(List<HttpExchange> all, String? id) {
  if (id == null) {
    return null;
  }
  for (final HttpExchange exchange in all) {
    if (exchange.id == id) {
      return exchange;
    }
  }
  return null;
}
