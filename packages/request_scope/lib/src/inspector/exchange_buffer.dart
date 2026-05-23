import 'dart:collection';

import '../models/http_exchange.dart';

/// Fixed-size FIFO buffer for [HttpExchange] values.
///
/// Stores at most [capacity] exchanges, dropping the oldest entries when the
/// buffer is full. The buffer is internally a [LinkedHashMap] keyed by
/// [HttpExchange.id] so that an exchange can be updated in place when its
/// response or error arrives.
class ExchangeBuffer {
  /// Creates an empty buffer with the supplied [capacity].
  ExchangeBuffer({this.capacity = 500})
    : assert(capacity > 0, 'capacity must be positive');

  /// Maximum number of exchanges retained.
  final int capacity;

  final LinkedHashMap<String, HttpExchange> _items =
      LinkedHashMap<String, HttpExchange>();

  /// Inserts or replaces [exchange] preserving insertion order.
  void upsert(HttpExchange exchange) {
    if (_items.containsKey(exchange.id)) {
      _items[exchange.id] = exchange;
      return;
    }
    if (_items.length >= capacity) {
      _items.remove(_items.keys.first);
    }
    _items[exchange.id] = exchange;
  }

  /// Returns the exchange with the given [id], or `null` when absent.
  HttpExchange? get(String id) => _items[id];

  /// All buffered exchanges in insertion order.
  List<HttpExchange> snapshot() =>
      List<HttpExchange>.unmodifiable(_items.values);

  /// Number of buffered exchanges.
  int get length => _items.length;

  /// Whether the buffer is empty.
  bool get isEmpty => _items.isEmpty;

  /// Drops every entry.
  void clear() => _items.clear();
}
