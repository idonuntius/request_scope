import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:request_scope/request_scope.dart';

import '../state/connection_controller.dart';
import '../state/exchange_store.dart';
import '../state/filters.dart';
import '../state/providers.dart';
import '../widgets/exchange_detail.dart';
import '../widgets/exchange_list.dart';
import '../widgets/inspector_toolbar.dart';

/// Top level screen of the request_scope DevTools extension.
class InspectorScreen extends ConsumerWidget {
  /// Creates a new [InspectorScreen].
  const InspectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly instantiate the connection controller so it starts listening to
    // the VM service even before the user interacts with the UI.
    ref.watch(connectionControllerProvider);

    final ExchangeStore store = ref.watch(exchangeStoreProvider);

    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, _) {
        final FilterState filter = ref.watch(filterProvider);
        final List<HttpExchange> all = store.value;
        final List<HttpExchange> visible = filterExchanges(all, filter);
        final String? selectedId = ref.watch(selectedExchangeIdProvider);
        final HttpExchange? selected = findExchange(all, selectedId);

        return Scaffold(
          body: Column(
            children: <Widget>[
              const InspectorToolbar(),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      width: 380,
                      child: ExchangeList(
                        exchanges: visible,
                        selectedId: selected?.id,
                        onSelected: (HttpExchange exchange) {
                          ref.read(selectedExchangeIdProvider.notifier).state =
                              exchange.id;
                        },
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: ExchangeDetail(exchange: selected)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
