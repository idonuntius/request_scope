import 'package:flutter/material.dart';
import 'package:request_scope/request_scope.dart';

import 'status_chip.dart';

/// Left column listing every captured [HttpExchange].
class ExchangeList extends StatelessWidget {
  /// Creates a new list widget.
  const ExchangeList({
    super.key,
    required this.exchanges,
    required this.selectedId,
    required this.onSelected,
  });

  /// Exchanges to render, already filtered.
  final List<HttpExchange> exchanges;

  /// Currently selected exchange identifier.
  final String? selectedId;

  /// Callback fired when the user picks an exchange.
  final ValueChanged<HttpExchange> onSelected;

  @override
  Widget build(BuildContext context) {
    if (exchanges.isEmpty) {
      return const _EmptyState();
    }
    return ListView.separated(
      itemCount: exchanges.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final HttpExchange exchange = exchanges[exchanges.length - 1 - index];
        final bool isSelected = exchange.id == selectedId;
        return _ExchangeTile(
          exchange: exchange,
          isSelected: isSelected,
          onTap: () => onSelected(exchange),
        );
      },
    );
  }
}

class _ExchangeTile extends StatelessWidget {
  const _ExchangeTile({
    required this.exchange,
    required this.isSelected,
    required this.onTap,
  });

  final HttpExchange exchange;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isPending = exchange.status == ExchangeStatus.pending;
    final Color background = isSelected
        ? colors.primaryContainer.withValues(alpha: 0.4)
        : Colors.transparent;
    final Duration? duration = exchange.duration;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            left: BorderSide(
              color: isPending ? colors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            _MethodBadge(method: exchange.request.method),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    exchange.request.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      StatusChip(exchange: exchange),
                      const SizedBox(width: 8),
                      if (duration != null)
                        Text(
                          _formatDuration(duration),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final HttpMethod method;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = switch (method) {
      HttpMethod.get => colors.primary.withValues(alpha: 0.12),
      HttpMethod.post => Colors.green.withValues(alpha: 0.15),
      HttpMethod.put ||
      HttpMethod.patch => Colors.orange.withValues(alpha: 0.18),
      HttpMethod.delete => Colors.red.withValues(alpha: 0.15),
      _ => colors.surfaceContainerHighest,
    };
    return Container(
      width: 56,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.wireName,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.wifi_tethering_outlined,
              size: 36,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Waiting for HTTP traffic…',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Make a request from your Flutter app to see it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  if (duration.inMilliseconds < 1) {
    return '${duration.inMicroseconds}µs';
  }
  if (duration.inSeconds < 1) {
    return '${duration.inMilliseconds}ms';
  }
  return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
}
