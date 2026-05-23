import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope_extension/src/state/exchange_store.dart';
import 'package:request_scope_extension/src/state/providers.dart';
import 'package:request_scope_extension/src/state/settings.dart';

void main() {
  group('capacityProvider', () {
    test(
      'initial read - exposes kDefaultCapacity and applies it to the store',
      () {
        final ProviderContainer container = ProviderContainer();
        addTearDown(container.dispose);

        final int initial = container.read(capacityProvider);
        final ExchangeStore store = container.read(exchangeStoreProvider);

        expect(initial, kDefaultCapacity);
        expect(store.capacity, kDefaultCapacity);
      },
    );
  });

  group('CapacityController.set', () {
    test('set with a valid value - updates both state and store.capacity', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(capacityProvider.notifier).set(250);

      expect(container.read(capacityProvider), 250);
      expect(container.read(exchangeStoreProvider).capacity, 250);
    });

    test('value below kMinCapacity - is clamped up to kMinCapacity', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(capacityProvider.notifier).set(10);

      expect(container.read(capacityProvider), kMinCapacity);
    });

    test('value above kMaxCapacity - is clamped down to kMaxCapacity', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(capacityProvider.notifier).set(99999);

      expect(container.read(capacityProvider), kMaxCapacity);
    });

    test('set to the current value - is a no-op', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final int before = container.read(capacityProvider);
      container.read(capacityProvider.notifier).set(before);

      expect(container.read(capacityProvider), before);
    });
  });

  group('CapacityController.reset', () {
    test('reset after a change - reverts to kDefaultCapacity', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(capacityProvider.notifier).set(2000);
      container.read(capacityProvider.notifier).reset();

      expect(container.read(capacityProvider), kDefaultCapacity);
    });
  });
}
