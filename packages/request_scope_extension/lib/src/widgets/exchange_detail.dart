import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:request_scope/request_scope.dart';

import '../utils/curl.dart';
import '../utils/exchange_text.dart';
import 'json_viewer.dart';
import 'status_chip.dart';

/// Right column rendering the full detail of a single [HttpExchange].
class ExchangeDetail extends StatelessWidget {
  /// Creates a new detail widget.
  const ExchangeDetail({super.key, required this.exchange});

  /// Currently selected exchange. When `null`, an empty state is shown.
  final HttpExchange? exchange;

  @override
  Widget build(BuildContext context) {
    final HttpExchange? value = exchange;
    if (value == null) {
      return _EmptyDetail();
    }
    final ThemeData theme = Theme.of(context);
    final TextStyle? title = theme.textTheme.titleSmall;
    final bool failed = value.status == ExchangeStatus.failed;
    return Container(
      color: failed
          ? Colors.redAccent.withValues(alpha: 0.04)
          : Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Summary(exchange: value),
          const SizedBox(height: 16),
          Text('Request', style: title),
          const SizedBox(height: 8),
          _RequestSection(value: value),
          const SizedBox(height: 24),
          Text('Response', style: title),
          const SizedBox(height: 8),
          _ResponseSection(value: value),
          if (value.error != null) ...<Widget>[
            const SizedBox(height: 24),
            Text('Error', style: title),
            const SizedBox(height: 8),
            _ErrorSection(value: value.error!),
          ],
        ],
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bolt_outlined,
              size: 36,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text('Select a request', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Pick an entry on the left to inspect its headers, body and timing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.exchange});

  final HttpExchange exchange;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              exchange.request.method.wireName,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                exchange.request.url,
                style: text.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            StatusChip(exchange: exchange),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            if (exchange.duration != null)
              _MetaPill(
                icon: Icons.timer_outlined,
                label: _formatDuration(exchange.duration!),
              ),
            _MetaPill(
              icon: Icons.schedule_outlined,
              label: _formatTime(exchange.request.timestamp),
            ),
            IconButton(
              tooltip: 'Copy as cURL',
              icon: const Icon(Icons.terminal),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: buildCurl(exchange.request)),
                );
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(
                    content: Text('Copied cURL command'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Copy full exchange',
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: formatExchange(exchange)),
                );
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(
                    content: Text('Copied full exchange'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _RequestSection extends StatelessWidget {
  const _RequestSection({required this.value});

  final HttpExchange value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (value.request.queryParameters.isNotEmpty) ...<Widget>[
          const _SubHeader('Query parameters'),
          _KeyValueGrid(entries: value.request.queryParameters),
          const SizedBox(height: 12),
        ],
        const _SubHeader('Headers'),
        _KeyValueGrid(entries: value.request.headers),
        const SizedBox(height: 12),
        const _SubHeader('Body'),
        JsonViewer(value: value.request.body),
      ],
    );
  }
}

class _ResponseSection extends StatelessWidget {
  const _ResponseSection({required this.value});

  final HttpExchange value;

  @override
  Widget build(BuildContext context) {
    final ResponseData? response = value.response;
    if (response == null) {
      return Text(
        value.status == ExchangeStatus.pending
            ? 'Waiting for response…'
            : 'No response captured.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SubHeader('Headers'),
        _KeyValueGrid(entries: response.headers),
        const SizedBox(height: 12),
        const _SubHeader('Body'),
        JsonViewer(value: response.body),
      ],
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.value});

  final ErrorData value;

  @override
  Widget build(BuildContext context) {
    final TextStyle? body = Theme.of(context).textTheme.bodyMedium;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (value.type != null)
            Text(
              value.type!,
              style: body?.copyWith(fontWeight: FontWeight.w600),
            ),
          if (value.message.isNotEmpty)
            SelectableText(value.message, style: body),
          if (value.stackTrace != null) ...<Widget>[
            const SizedBox(height: 8),
            JsonViewer(value: value.stackTrace),
          ],
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.entries});

  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text('(none)', style: Theme.of(context).textTheme.bodySmall);
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < entries.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: i.isEven
                    ? colors.surfaceContainerHighest.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 160,
                    child: SelectableText(
                      entries.keys.elementAt(i),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      entries.values.elementAt(i),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
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

String _formatTime(DateTime time) {
  String pad(int v) => v.toString().padLeft(2, '0');
  return '${pad(time.hour)}:${pad(time.minute)}:${pad(time.second)}.${pad((time.millisecond / 10).floor())}';
}
