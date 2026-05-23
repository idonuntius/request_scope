# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-18

### Added

- Initial release.
- Transport-agnostic data model (`HttpExchange`, `RequestData`, `ResponseData`,
  `ErrorData`) and event protocol (`RequestStartedEvent`,
  `ResponseReceivedEvent`, `RequestFailedEvent`, `BufferClearedEvent`,
  `SnapshotEvent`).
- `RequestScopeInspector` with bounded ring buffer, body truncation and an
  `enabled` flag for release builds.
- VM service plumbing: posts custom events on the `Extension` stream and
  exposes `ext.requestScope.{getExchanges,clear,config}` service extensions.
- Bundled DevTools extension configuration (`extension/devtools/config.yaml`).
