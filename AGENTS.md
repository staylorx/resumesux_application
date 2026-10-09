# ResumesUX Application

This package is built to the **taybiz/dart-flutter-bible** (private clone:
`C:/awork_local/mine/dart-flutter-bible`; the token-cheap ingest blob is
`docs/00-compact.md`). Read the doctrine **before** judging anything in this
repo. This file carries **only this repo's deviations and local wiring** — it
never restates bible rules (D.R.Y.: a second copy is a second truth).

## Layer & wiring

- Application-layer package: contracts + usecases, layered **over** the
  `resumesux_domain` package (git dependency). Domain inner → application
  outer; never import platform/IO from a usecase.
- One hand-written barrel: `lib/resumesux_application.dart` (a `library;`
  re-export of `src/`). No `src/` library may import the barrel (front-door
  closed) — enforced by the boundary gate.
- `test/architecture_test.dart` is the `dart_arch_test` boundary gate (§2.9):
  production code is cycle-free, no `src/` library re-enters through the public
  barrel, and `repositories/` + `services/` never depend on `usecases/`.
- `test/support/test_suite_tool.dart` is a salvaged test-suite-to-README
  reporter (mixin) for recording manual/integration runs — test scaffolding,
  not shipped API.

## Error style (declared)

- **Default error style: functional.** Asynchronous operations return
  `TaskEither<Failure, T>` (fpdart). Repositories return `TaskEither`, usecases
  return `TaskEither`, services return `TaskEither`.
- `Failure` (`lib/src/failure.dart`) is the domain/application error base;
  concrete failures extend it.
- **Plain exceptions are reserved for the UI/presentation ring only** — never
  thrown or `try`/`catch`-ed across a usecase boundary.

## Known deviations (tracked)

- `analysis_options.yaml` strict block is partial: it has `strict-casts` and
  `strict-raw-types`, but is missing `strict-inference`, `todo: error`, and
  `public_member_api_docs` (§2.2 / §9.7).
- The local `resumesux_cli` and `resumesux_infrastructure` folders were
  **superseded** by this repo + `resumesux_domain` (2026-10 consolidation) and
  deleted; this repository's contracts/usecases are the canonical versions.

## Working agreement (velocity)

> If your work is all green — gate green, everything formatted, analyzed,
> coveraged, tested, CI'd to death, and good enough to tell the user you're
> done — then it's good enough to commit, push to main, and delete the branch.
> Do it without being asked. Don't leave a finished task sitting on a branch
> or in a dirty working tree waiting for permission. This repo will move to
> PRs eventually; for now the flow is direct-to-main. Velocity wins.
