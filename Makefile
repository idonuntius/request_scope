.PHONY: get analyze format test fix clean extension example build-extension copy-extension publish-dry

get:
	flutter pub get

analyze:
	dart analyze

format:
	dart format .

test:
	flutter test packages/request_scope packages/request_scope_dio
	cd packages/request_scope_extension && flutter test --platform chrome

test-coverage:
	flutter test packages/request_scope --coverage --coverage-path=packages/request_scope/coverage/lcov.info
	flutter test packages/request_scope_dio --coverage --coverage-path=packages/request_scope_dio/coverage/lcov.info
	cd packages/request_scope_extension && flutter test --platform chrome --coverage --coverage-path=coverage/lcov.info

fix:
	dart fix --apply

clean:
	flutter clean
	cd example && flutter clean
	cd packages/request_scope && flutter clean
	cd packages/request_scope_dio && flutter clean
	cd packages/request_scope_extension && flutter clean

extension:
	cd packages/request_scope_extension && flutter run -d chrome

example:
	cd example && flutter run -d chrome

build-extension:
	cd packages/request_scope_extension && flutter build web \
		--csp \
		--output ../request_scope/extension/devtools/build

copy-extension: build-extension
	@echo "DevTools extension built into packages/request_scope/extension/devtools/build"

publish-dry:
	cd packages/request_scope && dart pub publish --dry-run
	cd packages/request_scope_dio && dart pub publish --dry-run
