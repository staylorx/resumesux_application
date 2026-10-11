# Backlog

Open / pending items only. Settled decisions and shipped changes live in
`CHANGELOG.md`; anything already fixed is deleted from here, not struck through.

## Build & analysis

- No `test/` directory — `dart test` exits 65; zero tests ship despite
  `test:`/`mocktail:` in `dev_dependencies`.
- `README.md` Testing section claims a test suite that does not exist.
- `pubspec.yaml` has no `homepage`/`repository` — `dart pub publish --dry-run`
  warns.
- `resumesux_domain` is a git dependency with no `ref:` pin — builds are not
  reproducible from `pubspec.lock` alone, and `pub publish` warns on the source.
- Two `TODO` comments sit in `lib/`; `todo` is mapped to `error`.
- No `AGENTS.md`, though this package deviates from the bible error style.
- No `analysis_options` gate for `public_member_api_docs` / `todo: error`.

## Deviations vs `staylorx/dart-flutter-bible` (flagged for review, NOT fixed)

- `pubspec.yaml` SDK `>=3.11.0 <4.0.0` vs the bible's `>=3.10.0 <4.0.0` floor.
- `analysis_options.yaml` diverges from the bible gate: `lints/recommended`
  base, no `public_member_api_docs`, `todo` not `error`, `invalid_assignment:
  warning`, and `prefer_const_constructors` both enabled and ignored.
- No `test/` or `dart_arch_test` — no boundary or cycle enforcement.
- Barrel `lib/resumesux_application.dart`: bare `library;`, no error-style doc,
  re-exports the whole domain barrel.
- Error style never declared: unrun `TaskEither<Failure, T>` seam used
  everywhere without declaration.
- `README.md`: runnable usage code referencing `UuidHandleGenerator()` and
  `ApplicantRepositoryImpl()` (neither exists), plus an "Architecture" section
  restating doctrine.
- `lib/src/failure.dart`: 17 failure classes in one flat non-`sealed` file, no
  `Equatable`; doc cites "dartz" while the code uses `fpdart`.
- Repository contracts live in the application package, not the domain package.
- Two `abstract class Transaction` (`repositories/`, `services/`); the
  `services/` copy is dead code.
- `dynamic get db` in `repositories/transaction.dart`; `dynamic transaction` on
  every `DatabaseService` method.
- `BasicCrudContract<T, TH, TWH>` cargo-shaped params, imports its own barrel
  from `src/`, takes `Transaction? txn` not `IUnitOfWork? uow`.
- `UnitOfWork` exposes manual `commit()`/`rollback()` besides `run()`.
- Hand-rolled document-store in `database_service.dart` (`Map<String, dynamic>`,
  `dynamic transaction`) standing in for drift/sembast.
- `try`/`catch` and `throw` inside use cases.
- `TaskEither.tryCatch` used inside use cases, not at an adapter boundary.
- `dart:io` used directly in application-layer use cases (`Directory`,
  `listSync`, `readAsString`, `Platform.pathSeparator`).
- Positional use-case parameters (`handle`).
- `get_application_usecase.dart`: `execute()` instead of `call()`,
  undocumented, absent from the barrel.
- Two `GetJobReqUsecase` classes; `get_jobreq_usercase.dart` (typo) is
  unreachable dead code.
- `Usecase` / `UseCase` naming is inconsistent across the package.
- Use cases taking domain cargo at construction (`applicant`, `jobReq`,
  `resume`, `coverLetter`, `feedback`); some fields unused.
- `update` paths pass whole handle-wrapped entities.
- Six `Save*AiResponseUsecase` swallow failures via `.orElse(right(unit))`.
- `generate_application_usecase.dart` threads a `progress` callback through the
  core; `jobReqId` derived from `Object.hashCode`.
- AI-generation use cases write side effects inside `.map()`.
- `GetJobReqUsecase` re-reads the file it just processed, discarding a value
  mid-chain.
- `test`/`mocktail` declared but `shouldly` absent.
- No pub workspace / single flat package.
