import 'package:flutter_test/flutter_test.dart';
import 'package:request_scope/request_scope.dart';
import 'package:request_scope_extension/src/state/filters.dart';

void main() {
  group('FilterState.matches (method)', () {
    test('method constraint matches - returns true', () {
      const FilterState filter = FilterState(
        methods: <HttpMethod>{HttpMethod.get},
      );
      expect(filter.matches(_exchange(HttpMethod.get)), isTrue);
    });

    test('method constraint does not match - returns false', () {
      const FilterState filter = FilterState(
        methods: <HttpMethod>{HttpMethod.get},
      );
      expect(filter.matches(_exchange(HttpMethod.post)), isFalse);
    });

    test('no method constraint - returns true for any method', () {
      const FilterState filter = FilterState();
      expect(filter.matches(_exchange(HttpMethod.delete)), isTrue);
    });
  });

  group('FilterState.matches (status)', () {
    test('success filter with a 2xx response - returns true', () {
      const FilterState filter = FilterState(status: StatusFilter.success);
      expect(filter.matches(_completed(204)), isTrue);
    });

    test('redirect filter with a 3xx response - returns true', () {
      const FilterState filter = FilterState(status: StatusFilter.redirect);
      expect(filter.matches(_completed(301)), isTrue);
    });

    test('clientError filter with a 4xx response - returns true', () {
      const FilterState filter = FilterState(status: StatusFilter.clientError);
      expect(filter.matches(_completed(404)), isTrue);
    });

    test('serverError filter with a 5xx response - returns true', () {
      const FilterState filter = FilterState(status: StatusFilter.serverError);
      expect(filter.matches(_completed(503)), isTrue);
    });

    test('pending filter with a pending exchange - returns true', () {
      const FilterState filter = FilterState(status: StatusFilter.pending);
      expect(filter.matches(_exchange(HttpMethod.get)), isTrue);
    });

    test('failed filter with a failed exchange - returns true', () {
      const FilterState filter = FilterState(status: StatusFilter.failed);
      expect(filter.matches(_failed()), isTrue);
    });

    test('success filter with a pending exchange - returns false', () {
      const FilterState filter = FilterState(status: StatusFilter.success);
      expect(filter.matches(_exchange(HttpMethod.get)), isFalse);
    });
  });

  group('FilterState.matches (search)', () {
    test('search string contained in the URL - returns true', () {
      const FilterState filter = FilterState(search: 'items');
      expect(
        filter.matches(_exchange(HttpMethod.get, url: 'https://x/items')),
        isTrue,
      );
    });

    test('search string matching the method name - returns true', () {
      const FilterState filter = FilterState(search: 'POST');
      expect(filter.matches(_exchange(HttpMethod.post)), isTrue);
    });

    test('search string nowhere to be found - returns false', () {
      const FilterState filter = FilterState(search: 'nothing');
      expect(filter.matches(_exchange(HttpMethod.get)), isFalse);
    });
  });

  group('FilterState.copyWith', () {
    test('overriding some fields - leaves the rest untouched', () {
      const FilterState original = FilterState(
        methods: <HttpMethod>{HttpMethod.get},
        status: StatusFilter.success,
        search: 'abc',
      );
      final FilterState updated = original.copyWith(search: 'xyz');

      expect(updated.methods, original.methods);
      expect(updated.status, original.status);
      expect(updated.search, 'xyz');
    });
  });

  group('StatusFilter.label', () {
    test('each enum value - exposes the expected label', () {
      expect(StatusFilter.all.label, 'All');
      expect(StatusFilter.success.label, '2xx');
      expect(StatusFilter.redirect.label, '3xx');
      expect(StatusFilter.clientError.label, '4xx');
      expect(StatusFilter.serverError.label, '5xx');
      expect(StatusFilter.pending.label, 'Pending');
      expect(StatusFilter.failed.label, 'Failed');
    });
  });
}

HttpExchange _exchange(
  HttpMethod method, {
  String url = 'https://example.com/x',
}) {
  return HttpExchange(
    id: 'id-${method.name}',
    request: RequestData(
      method: method,
      url: url,
      headers: const <String, String>{},
      queryParameters: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20),
    ),
  );
}

HttpExchange _completed(int code) {
  return HttpExchange(
    id: 'c',
    request: RequestData(
      method: HttpMethod.get,
      url: 'https://example.com/c',
      headers: const <String, String>{},
      queryParameters: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20),
    ),
    response: ResponseData(
      statusCode: code,
      headers: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
      duration: const Duration(milliseconds: 10),
    ),
  );
}

HttpExchange _failed() {
  return HttpExchange(
    id: 'f',
    request: RequestData(
      method: HttpMethod.get,
      url: 'https://example.com/f',
      headers: const <String, String>{},
      queryParameters: const <String, String>{},
      timestamp: DateTime.utc(2026, 5, 20),
    ),
    error: ErrorData(
      message: 'boom',
      timestamp: DateTime.utc(2026, 5, 20, 0, 0, 1),
    ),
  );
}
