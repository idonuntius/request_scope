import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pretty JSON viewer with monospace font, copy button and graceful fallback
/// for non-JSON payloads.
class JsonViewer extends StatelessWidget {
  /// Creates a new viewer.
  const JsonViewer({super.key, required this.value, this.maxHeight = 280});

  /// The value to render. Maps and lists are pretty printed as JSON; everything
  /// else is rendered using [Object.toString].
  final Object? value;

  /// Maximum scrollable height.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final String pretty = _pretty(value);
    final ThemeData theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: SelectableText(
                  pretty.isEmpty ? '(empty)' : pretty,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pretty));
              },
            ),
          ),
        ],
      ),
    );
  }

  String _pretty(Object? source) {
    if (source == null) {
      return '';
    }
    if (source is String) {
      final String trimmed = source.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final Object? parsed = jsonDecode(trimmed);
          return _encoder.convert(parsed);
        } catch (_) {
          // fall through and return raw string.
        }
      }
      return source;
    }
    if (source is Map || source is List) {
      try {
        return _encoder.convert(source);
      } catch (_) {
        return source.toString();
      }
    }
    return source.toString();
  }
}

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
