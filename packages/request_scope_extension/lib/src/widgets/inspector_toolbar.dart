import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:request_scope/request_scope.dart';

import '../state/connection_controller.dart';
import '../state/filters.dart';
import '../state/providers.dart';
import 'settings_dialog.dart';

/// Top toolbar exposing the method, status and search filters as well as
/// global actions (refresh, clear).
class InspectorToolbar extends ConsumerWidget {
  /// Creates a new toolbar.
  const InspectorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FilterState filter = ref.watch(filterProvider);
    final ConnectionController controller = ref.read(
      connectionControllerProvider,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Icon(Icons.travel_explore, color: colors.primary),
          const Text(
            'request_scope',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 8),
          _MethodFilter(
            value: filter.methods,
            onChanged: (Set<HttpMethod> next) {
              ref.read(filterProvider.notifier).state = filter.copyWith(
                methods: next,
              );
            },
          ),
          _StatusFilter(
            value: filter.status,
            onChanged: (StatusFilter next) {
              ref.read(filterProvider.notifier).state = filter.copyWith(
                status: next,
              );
            },
          ),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Search url, status, method…',
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                ref.read(filterProvider.notifier).state = filter.copyWith(
                  search: value,
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Refresh from app',
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
          ),
          IconButton(
            tooltip: 'Clear captured exchanges',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: controller.clearRemoteBuffer,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => SettingsDialog.show(context),
          ),
        ],
      ),
    );
  }
}

class _MethodFilter extends StatelessWidget {
  const _MethodFilter({required this.value, required this.onChanged});

  final Set<HttpMethod> value;
  final ValueChanged<Set<HttpMethod>> onChanged;

  static const List<HttpMethod> _options = <HttpMethod>[
    HttpMethod.get,
    HttpMethod.post,
    HttpMethod.put,
    HttpMethod.patch,
    HttpMethod.delete,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: <Widget>[
        for (final HttpMethod method in _options)
          FilterChip(
            label: Text(method.wireName),
            selected: value.contains(method),
            onSelected: (bool selected) {
              final Set<HttpMethod> next = <HttpMethod>{...value};
              if (selected) {
                next.add(method);
              } else {
                next.remove(method);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.value, required this.onChanged});

  final StatusFilter value;
  final ValueChanged<StatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<StatusFilter>(
      value: value,
      isDense: true,
      onChanged: (StatusFilter? next) {
        if (next != null) {
          onChanged(next);
        }
      },
      items: <DropdownMenuItem<StatusFilter>>[
        for (final StatusFilter option in StatusFilter.values)
          DropdownMenuItem<StatusFilter>(
            value: option,
            child: Text(option.label),
          ),
      ],
    );
  }
}
