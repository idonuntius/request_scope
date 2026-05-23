import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';

void main() {
  group('RequestScopeServiceKeys', () {
    test(
      'service extension method names - use the ext.requestScope.* prefix',
      () {
        expect(
          RequestScopeServiceKeys.getExchangesMethod,
          'ext.requestScope.getExchanges',
        );
        expect(RequestScopeServiceKeys.clearMethod, 'ext.requestScope.clear');
        expect(RequestScopeServiceKeys.configMethod, 'ext.requestScope.config');
      },
    );

    test('event names - use the request_scope.* prefix', () {
      expect(RequestScopeServiceKeys.requestEvent, 'request_scope.request');
      expect(RequestScopeServiceKeys.responseEvent, 'request_scope.response');
      expect(RequestScopeServiceKeys.errorEvent, 'request_scope.error');
      expect(RequestScopeServiceKeys.clearEvent, 'request_scope.clear');
    });

    test(
      'extensionStreamId - matches the VM service Extension stream name',
      () {
        expect(RequestScopeServiceKeys.extensionStreamId, 'Extension');
      },
    );
  });
}
