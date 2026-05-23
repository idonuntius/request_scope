import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/settings.dart';

/// Modal dialog that lets the user tune the [ExchangeStore.capacity] retained
/// by the extension. Persists changes via `localStorage`.
class SettingsDialog extends ConsumerStatefulWidget {
  /// Creates a new settings dialog.
  const SettingsDialog({super.key});

  /// Opens the dialog as a modal.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(capacityProvider).toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final int? parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      setState(() => _error = 'Enter an integer');
      return;
    }
    if (parsed < kMinCapacity || parsed > kMaxCapacity) {
      setState(
        () => _error = 'Use a value between $kMinCapacity and $kMaxCapacity',
      );
      return;
    }
    ref.read(capacityProvider.notifier).set(parsed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final int current = ref.watch(capacityProvider);
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Exchange retention',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Maximum number of HTTP exchanges kept in the inspector UI. '
              'Lower this if DevTools feels sluggish on this machine. '
              '(current: $current)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Capacity',
                helperText: 'Between $kMinCapacity and $kMaxCapacity',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _apply(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            ref.read(capacityProvider.notifier).reset();
            _controller.text = kDefaultCapacity.toString();
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _apply, child: const Text('Apply')),
      ],
    );
  }
}
