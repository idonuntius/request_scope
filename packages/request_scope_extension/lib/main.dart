import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/inspector_app.dart';

void main() {
  runApp(const ProviderScope(child: _RequestScopeExtensionRoot()));
}

class _RequestScopeExtensionRoot extends StatelessWidget {
  const _RequestScopeExtensionRoot();

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: InspectorApp());
  }
}
