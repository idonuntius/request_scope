import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exchange_store.dart';
import 'providers.dart';

/// Smallest capacity the UI allows. A value too low makes the inspector
/// unusable.
const int kMinCapacity = 50;

/// Largest capacity the UI allows. Beyond this point the DevTools tab risks
/// running out of memory on lower-spec machines.
const int kMaxCapacity = 10000;

/// Default capacity, used the first time the extension is opened.
const int kDefaultCapacity = 1000;

/// User-tunable capacity for [ExchangeStore]. The value lives in memory only —
/// reopening the DevTools tab resets it to [kDefaultCapacity].
final StateNotifierProvider<CapacityController, int> capacityProvider =
    StateNotifierProvider<CapacityController, int>((Ref ref) {
      final ExchangeStore store = ref.watch(exchangeStoreProvider);
      store.capacity = kDefaultCapacity;
      return CapacityController(store: store);
    });

/// Manages the user-configurable [ExchangeStore.capacity] value.
class CapacityController extends StateNotifier<int> {
  /// Creates a controller around [store].
  CapacityController({required ExchangeStore store})
    : _store = store,
      super(kDefaultCapacity);

  final ExchangeStore _store;

  /// Updates the capacity and applies it to the store.
  void set(int value) {
    final int clamped = value.clamp(kMinCapacity, kMaxCapacity);
    if (clamped == state) {
      return;
    }
    state = clamped;
    _store.capacity = clamped;
  }

  /// Resets the capacity back to [kDefaultCapacity].
  void reset() => set(kDefaultCapacity);
}
