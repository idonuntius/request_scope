import 'package:flutter/material.dart';
import 'package:request_scope/request_scope.dart';

/// Compact chip describing the status of an [HttpExchange]. Renders a small
/// spinner while the exchange is still in flight so the user can distinguish
/// pending from completed at a glance.
class StatusChip extends StatelessWidget {
  /// Creates a new [StatusChip].
  const StatusChip({super.key, required this.exchange});

  /// Exchange to render.
  final HttpExchange exchange;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (exchange.status == ExchangeStatus.pending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'pending',
              style: TextStyle(
                color: colors.primary,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Prefer showing the HTTP status code when available, even for failed
    // exchanges (e.g. a 404 or 500 carries more information than "ERR"). Only
    // fall back to "ERR" when the request never reached a response (network
    // failure, timeout, etc.).
    final int? code = exchange.response?.statusCode;
    final String label;
    final Color color;
    if (code != null && code > 0) {
      label = code.toString();
      color = _statusColor(code);
    } else {
      label = 'ERR';
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _statusColor(int code) {
    if (code >= 500) return Colors.redAccent;
    if (code >= 400) return Colors.orange;
    if (code >= 300) return Colors.amber;
    if (code >= 200) return Colors.green;
    return Colors.grey;
  }
}
