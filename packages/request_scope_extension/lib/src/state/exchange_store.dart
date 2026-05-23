import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:request_scope/request_scope.dart';

/// In-memory store of [HttpExchange] values displayed by the extension.
///
/// Exposes a [ValueListenable] interface so that simple consumers can rebuild
/// without depending on Riverpod. The store is bounded by [capacity]; once the
/// limit is reached, the oldest entries are dropped first so the latest
/// traffic is always visible.
class ExchangeStore extends ChangeNotifier
    implements ValueListenable<List<HttpExchange>> {
  /// Creates a new store with [capacity] retained exchanges.
  ExchangeStore({int capacity = 1000})
    : assert(capacity > 0, 'capacity must be positive'),
      _capacity = capacity;

  int _capacity;

  /// Maximum number of exchanges retained.
  int get capacity => _capacity;

  /// Updates the retention limit. The store trims its content immediately if
  /// the new [value] is smaller than the current size.
  set capacity(int value) {
    assert(value > 0, 'capacity must be positive');
    if (value == _capacity) {
      return;
    }
    _capacity = value;
    if (_items.length > _capacity) {
      _trim();
      notifyListeners();
    }
  }

  final LinkedHashMap<String, HttpExchange> _items =
      LinkedHashMap<String, HttpExchange>();

  @override
  List<HttpExchange> get value =>
      List<HttpExchange>.unmodifiable(_items.values);

  /// Total number of exchanges currently tracked.
  int get length => _items.length;

  /// Replaces the entire collection with [exchanges]. Honors [capacity] by
  /// keeping the most recent entries when the input is longer.
  void replaceAll(Iterable<HttpExchange> exchanges) {
    _items.clear();
    for (final HttpExchange exchange in exchanges) {
      _items[exchange.id] = exchange;
    }
    _trim();
    notifyListeners();
  }

  /// Applies an event from the connected app.
  void apply(RequestScopeEvent event) {
    switch (event) {
      case RequestStartedEvent():
        _upsert(HttpExchange(id: event.exchangeId, request: event.request));
      case ResponseReceivedEvent():
        final HttpExchange? existing = _items[event.exchangeId];
        if (existing != null) {
          _items[event.exchangeId] = existing.copyWith(
            response: event.response,
          );
          notifyListeners();
        }
      case RequestFailedEvent():
        final HttpExchange? existing = _items[event.exchangeId];
        if (existing != null) {
          _items[event.exchangeId] = existing.copyWith(error: event.error);
          notifyListeners();
        }
      case BufferClearedEvent():
        clear();
      case SnapshotEvent():
        replaceAll(event.exchanges);
    }
  }

  /// Drops every tracked exchange.
  void clear() {
    if (_items.isEmpty) {
      return;
    }
    _items.clear();
    notifyListeners();
  }

  void _upsert(HttpExchange exchange) {
    if (_items.containsKey(exchange.id)) {
      _items[exchange.id] = exchange;
    } else {
      _items[exchange.id] = exchange;
      _trim();
    }
    notifyListeners();
  }

  void _trim() {
    while (_items.length > _capacity) {
      _items.remove(_items.keys.first);
    }
  }
}
