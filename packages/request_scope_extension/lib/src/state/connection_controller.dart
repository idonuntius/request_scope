import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:request_scope/request_scope.dart';
import 'package:vm_service/vm_service.dart';

import 'exchange_store.dart';
import 'providers.dart';

/// Exposes the controller that wires the VM service to the store.
final Provider<ConnectionController> connectionControllerProvider =
    Provider<ConnectionController>((Ref ref) {
      final ExchangeStore store = ref.watch(exchangeStoreProvider);
      final ConnectionController controller = ConnectionController(
        store: store,
        ref: ref,
      )..start();
      ref.onDispose(() {
        controller.dispose();
      });
      return controller;
    });

/// Listens to the VM service via the DevTools extension framework and forwards
/// every relevant event into the [ExchangeStore].
class ConnectionController {
  /// Creates a controller that pushes events to [store].
  ConnectionController({required this.store, required this.ref});

  /// Store updated when events arrive.
  final ExchangeStore store;

  /// Reference into the Riverpod container for cross-provider notifications.
  final Ref ref;

  StreamSubscription<Event>? _eventSubscription;
  VoidCallback? _connectionListener;
  bool _hasFetchedInitialSnapshot = false;
  Timer? _pollTimer;

  /// Starts listening to VM service connection changes. Safe to call multiple
  /// times.
  void start() {
    _connectionListener ??= _onConnectionChanged;
    serviceManager.connectedState.addListener(_connectionListener!);
    // Defer to the next microtask so the constructor finishes before we touch
    // the (possibly not-yet-initialized) service manager state.
    scheduleMicrotask(_onConnectionChanged);
  }

  /// Stops listening and releases resources.
  Future<void> dispose() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_connectionListener != null) {
      serviceManager.connectedState.removeListener(_connectionListener!);
      _connectionListener = null;
    }
    await _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  void _onConnectionChanged() {
    try {
      final ConnectedState state = serviceManager.connectedState.value;
      if (!state.connected) {
        _eventSubscription?.cancel();
        _eventSubscription = null;
        _pollTimer?.cancel();
        _pollTimer = null;
        _hasFetchedInitialSnapshot = false;
        return;
      }

      final VmService? service = serviceManager.service;
      if (service == null) {
        return;
      }

      _eventSubscription?.cancel();
      _eventSubscription = service.onExtensionEvent.listen(
        _handleExtensionEvent,
      );

      if (!_hasFetchedInitialSnapshot) {
        _hasFetchedInitialSnapshot = true;
        unawaited(_fetchSnapshot());
      }

      _pollTimer?.cancel();
      // Poll quickly so requests that are still in-flight appear briefly as
      // pending in the UI. 500ms is fast enough for human perception while
      // staying well under the typical request round-trip time.
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => unawaited(_fetchSnapshot()),
      );
    } catch (error, stackTrace) {
      developer.log(
        'connection change handler failed',
        name: 'request_scope_extension',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleExtensionEvent(Event event) {
    final String kind = event.extensionKind ?? '';
    if (!kind.startsWith('request_scope.')) {
      return;
    }
    final Map<String, dynamic>? raw = event.extensionData?.data;
    if (raw == null) {
      return;
    }
    final Map<String, Object?> payload = Map<String, Object?>.from(raw);
    try {
      final RequestScopeEvent decoded = RequestScopeEvent.fromJson(payload);
      store.apply(decoded);
    } catch (error, stackTrace) {
      developer.log(
        'failed to decode extension event $kind',
        name: 'request_scope_extension',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _fetchSnapshot() async {
    try {
      final Response response = await serviceManager
          .callServiceExtensionOnMainIsolate(
            RequestScopeServiceKeys.getExchangesMethod,
          );
      final Map<String, dynamic> json = response.json ?? <String, dynamic>{};
      final Map<String, Object?> payload = Map<String, Object?>.from(json);
      final RequestScopeEvent decoded = RequestScopeEvent.fromJson(payload);
      if (decoded is SnapshotEvent) {
        store.replaceAll(decoded.exchanges);
      }
    } catch (error, stackTrace) {
      developer.log(
        'fetch snapshot failed',
        name: 'request_scope_extension',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Asks the connected app to clear its buffer.
  Future<void> clearRemoteBuffer() async {
    if (!serviceManager.connectedState.value.connected) {
      store.clear();
      return;
    }
    try {
      await serviceManager.callServiceExtensionOnMainIsolate(
        RequestScopeServiceKeys.clearMethod,
      );
    } catch (error, stackTrace) {
      developer.log(
        'clear remote buffer failed',
        name: 'request_scope_extension',
        error: error,
        stackTrace: stackTrace,
      );
    }
    store.clear();
  }

  /// Re-fetches the buffered exchanges from the connected app.
  Future<void> refresh() async {
    await _fetchSnapshot();
  }
}

/// Convenience for serialising a payload for log inspection.
String describeEvent(RequestScopeEvent event) => jsonEncode(event.toJson());
