# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- ID generator no longer overflows on Flutter Web. `1 << 32` evaluates to `0`
  on dart2js/DDC, which caused `Random.nextInt(0)` to throw and silently
  skip every request capture on the web.

## [0.1.0] - 2026-05-18

### Added

- Initial release.
- `RequestScopeDioInterceptor` capturing HTTP method, URL, headers, query
  parameters, request and response bodies, status code, duration, timestamps,
  errors and stack traces.
- Form data is serialised to a transport-friendly representation so it
  renders cleanly in the DevTools extension.
- Errors that include a `Response` also record the response payload so users
  can inspect the failing server output.
