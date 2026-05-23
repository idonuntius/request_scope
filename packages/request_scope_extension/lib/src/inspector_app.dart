import 'package:flutter/material.dart';

import 'screens/inspector_screen.dart';

/// Root widget of the request_scope DevTools extension. The hosting
/// [DevToolsExtension] already supplies a Material themed [MaterialApp]; this
/// widget only adds the inspector workspace below it.
class InspectorApp extends StatelessWidget {
  /// Creates a new [InspectorApp].
  const InspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const InspectorScreen();
  }
}
