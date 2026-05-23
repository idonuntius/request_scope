import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_dio/request_scope_dio.dart';

void main() {
  RequestScopeInspector.instance.config = const RequestScopeConfig(
    // Disable in release builds. The DevTools extension is a debug tool only.
    enabled: kDebugMode || kProfileMode,
    bufferCapacity: 500,
  );

  runApp(const RequestScopeDemoApp());
}

/// Top level widget for the example app.
class RequestScopeDemoApp extends StatelessWidget {
  /// Creates the demo app.
  const RequestScopeDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'request_scope demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const DemoHomePage(),
    );
  }
}

/// Home screen with buttons that trigger sample HTTP requests.
class DemoHomePage extends StatefulWidget {
  /// Creates the home page.
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  late final Dio _dio;
  String _lastResult = 'Tap a button to issue an HTTP request.';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        headers: const <String, String>{'Accept': 'application/json'},
      ),
    )..interceptors.add(RequestScopeDioInterceptor());
  }

  Future<void> _run(Future<dynamic> Function() body, String label) async {
    setState(() {
      _busy = true;
      _lastResult = 'Running $label…';
    });
    try {
      final dynamic value = await body();
      setState(() {
        _lastResult =
            '$label → ${value is List ? '${value.length} items' : value.toString()}';
      });
    } on DioException catch (error) {
      setState(() {
        _lastResult = '$label → ${error.type.name}: ${error.message ?? ''}';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('request_scope demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Open Flutter DevTools and switch to the "request_scope" tab to '
              'inspect every request issued from this app in real time.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          final Response<dynamic> response = await _dio
                              .get<dynamic>(
                                '/posts',
                                queryParameters: <String, dynamic>{'_limit': 5},
                              );
                          return response.data;
                        }, 'GET /posts'),
                  icon: const Icon(Icons.download),
                  label: const Text('GET /posts'),
                ),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          final Response<dynamic> response = await _dio
                              .post<dynamic>(
                                '/posts',
                                data: <String, Object?>{
                                  'title': 'request_scope',
                                  'body': 'is awesome',
                                  'userId': 1,
                                },
                              );
                          return response.data;
                        }, 'POST /posts'),
                  icon: const Icon(Icons.upload),
                  label: const Text('POST /posts'),
                ),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => _dio.put<dynamic>(
                            '/posts/1',
                            data: <String, Object?>{'title': 'Updated title'},
                          ),
                          'PUT /posts/1',
                        ),
                  icon: const Icon(Icons.edit),
                  label: const Text('PUT /posts/1'),
                ),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => _dio.delete<dynamic>('/posts/1'),
                          'DELETE /posts/1',
                        ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('DELETE /posts/1'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => _dio.get<dynamic>('/this-does-not-exist'),
                          'GET 404',
                        ),
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Trigger 404'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final id =
                        'manual-${DateTime.now().millisecondsSinceEpoch}';
                    RequestScopeInspector.instance.recordRequest(
                      exchangeId: id,
                      request: RequestData(
                        method: HttpMethod.get,
                        url: 'https://manual-test.example.com/$id',
                        headers: const <String, String>{'X-Manual': 'yes'},
                        queryParameters: const <String, String>{},
                        timestamp: DateTime.now(),
                      ),
                    );
                    RequestScopeInspector.instance.recordResponse(
                      exchangeId: id,
                      response: ResponseData(
                        statusCode: 200,
                        headers: const <String, String>{},
                        body: const <String, String>{'manual': 'true'},
                        timestamp: DateTime.now(),
                        duration: const Duration(milliseconds: 1),
                      ),
                    );
                    // ignore: avoid_print
                    print(
                      '[rs_debug] manual record done. buffer='
                      '${RequestScopeInspector.instance.snapshot().length}',
                    );
                    setState(() {
                      _lastResult =
                          'Manual record → buffer=${RequestScopeInspector.instance.snapshot().length}';
                    });
                  },
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Manual record (skip Dio)'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Text(_lastResult, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
