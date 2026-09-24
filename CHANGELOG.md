# Changelog

All notable changes to `resumesux_application` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `BACKLOG.md` — the repo's open/pending backlog. First entry set covers the
  Windows-lane build and analysis audit and every divergence from the
  `staylorx/dart-flutter-bible` doctrine found during it.
- `CHANGELOG.md` — this file, following Keep a Changelog.

### Changed

- `lib/src/usecases/get_job_req_usecase.dart` — reformatted with
  `dart format` (the file was the only one in `lib/` failing
  `dart format --output=none --set-exit-if-changed`).

### Fixed

- `lib/src/usecases/yaml_digest/extract_applicant_from_digest_usecase.dart` —
  removed the redundant `package:resumesux_domain/resumesux_domain.dart` import
  (everything used was already provided by the package barrel). This was the last
  diagnostic standing between the repo and a clean
  `dart analyze --fatal-infos --fatal-warnings`; analyze now reports
  `No issues found!`.

### Decisions

- **Build and analysis findings live in `BACKLOG.md`; decisions live here.**
  Problems stay open in the backlog; anything acted on or settled is recorded in
  this changelog instead.
- **Doctrine divergences are recorded, not fixed.** Every difference from
  `staylorx/dart-flutter-bible` (13 sections, `docs/`) is written up in
  `BACKLOG.md` as a `Deviation:` item, because the bible itself may be the side
  that is wrong. None were changed in this pass.
- **Only two code changes were made, both non-semantic:** one `dart format` pass
  over a single mis-formatted file, and the removal of one redundant import.
  No behaviour, API, or type changed.
- **Push target is `main`.** The repository has no release or long-lived branch;
  the audit commit belongs on `main`.
- `pubspec.yaml` is intentionally left at `publish_to: none`; `dart pub publish
  --dry-run` still runs and is used as a packaging check (see `BACKLOG.md`).

### Notes

- Audited on the Windows lane with Dart SDK 3.13.1 at `main` @ `d4c1026`.
- Gate results after the fixes above: `dart pub get` OK,
  `dart analyze --fatal-infos --fatal-warnings` exit 0,
  `dart format --set-exit-if-changed lib` exit 0,
  `dart test` **exit 65** (no `test/` directory — open backlog item),
  `dart pub publish --dry-run` exit 65 with 2 warnings (open backlog items).

## [1.0.0] - 2026-09-24

The current version of the package (`pubspec.yaml`). No changelog was kept before
this date, so the work that produced 1.0.0 is not reconstructed here — this file
starts tracking from the version in the tree at that point.

[Unreleased]: https://github.com/staylorx/resumesux_application/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/staylorx/resumesux_application/releases/tag/v1.0.0
