# Backlog

Open / pending items only. Settled decisions and shipped changes live in
`CHANGELOG.md`; anything already fixed is deleted from here, not struck through.

## Build & analysis (Windows lane, Dart SDK 3.13.1)

Gates run on `main` @ `d4c1026`, after this audit's fixes (see `CHANGELOG.md`):

- `dart pub get` — OK (resolves `fpdart 1.2.0`, `equatable 2.1.0`; one
  newer-but-incompatible version noted for `equatable`)
- `dart analyze --fatal-infos --fatal-warnings` — exit 0, `No issues found!`
- `dart format --output=none --set-exit-if-changed lib` — exit 0, 0 changed
- `dart test` — **exit 65**, `No test files were passed and the default "test/"
  directory doesn't exist.`
- `dart pub publish --dry-run` — exit 65, 2 warnings (see below)

Problems found, open:

- **`test/` does not exist — `dart test` fails with exit 65.** `pubspec.yaml`
  declares `test: ^1.28.0` and `mocktail: ^1.0.4` in `dev_dependencies`, but the
  package ships zero tests. Nothing in this repo is under test, and the CI test
  gate cannot even start. **Recommendation: add `test/` with the use-case tests
  (mocktail at the repository seam, both `Either` sides) before any further
  refactor** — see the testing deviations below for the doctrine shape.

- **`README.md` claims a test suite that does not exist.** The Testing section
  says "The test suite includes unit tests for use cases and repository
  contracts." There is no `test/` directory. **Recommendation: delete the claim
  or make it true (preferred: make it true).**

- **`pubspec.yaml` has no `homepage`/`repository`** — `dart pub publish
  --dry-run` warns on it. **Recommendation: add `repository:
  https://github.com/staylorx/resumesux_application`.**

- **`resumesux_domain` is a git dependency with no `ref:`.** `pubspec.yaml`
  declares `url:` only, so the resolver tracks the domain repo's default-branch
  HEAD and builds are not reproducible from `pubspec.lock` alone. `pub publish
  --dry-run` also warns against the git source entirely. **Recommendation: pin
  the git dependency to a commit SHA (or a tag) and bump deliberately; consider
  publishing the domain package and using the hosted source.**

- **Two `TODO` comments sit in `lib/`** (`src/repositories/business/
  job_req_repository.dart:22`, `src/services/database_service.dart:2`). The bible
  maps `todo` to `error` in `analysis_options.yaml`, which would make both a
  compile error. **Recommendation: turn both into backlog items here (they
  already are: see the deviations below) and delete the comments.**

- **No `AGENTS.md`.** The task notes assume one exists. The bible requires one
  whenever a package deviates from the `Future<Either<...>>` default error style
  — which this package does (see deviations). **Recommendation: add a short
  `AGENTS.md` recording this repo's deviations and local wiring only.**

- **No `analysis_options` gate for this repo's shape rules.** `public_member_api_docs`
  and `todo: error` are absent, so missing docs and TODOs are not caught by
  analyze. See the toolchain deviations below.

## Deviations vs `staylorx/dart-flutter-bible` (flagged for review, NOT fixed)

A deviation is a place where the code differs from the bible and the bible might
itself be wrong. These are recorded, not resolved.

- **Deviation: `pubspec.yaml` — SDK constraint is `>=3.11.0 <4.0.0`; the bible
  pins `>=3.10.0 <4.0.0` in every pubspec.** A higher floor cuts off Dart 3.10
  consumers for no stated reason. Flagged because the bible floor may itself be
  stale (the current stable is 3.13.x). Do not auto-change.

- **Deviation: `analysis_options.yaml` — the analyzer config diverges from the
  bible's gate in several ways.** It is based on `package:lints/recommended.yaml`
  (not the bible's lint set), it omits `public_member_api_docs` and does not map
  `todo: error`, it carries a commented-out `# todo: ignore` line, it downgrades a
  default error to a warning (`invalid_assignment: warning`), and it lists
  `prefer_const_constructors` under `linter.rules` while setting it to `ignore`
  under `analyzer.errors` (self-contradictory — the rule is enabled and disabled
  in the same file). Flagged: some of these look deliberate and may be defensible,
  but they are silent, and the bible requires the analyzer gate to be zero-tolerance.

- **Deviation: no `test/`, no `dart_arch_test` boundary test.** The bible makes a
  `dart_arch_test` test the CI hard gate for package-boundary direction and
  cycle-freedom. With no `test/` directory at all there is no boundary enforcement
  of any kind. Flagged: within a single package the boundary rule is partly moot,
  which may be why it was skipped — but then the package split itself is the
  deviation (below).

- **Deviation: `lib/resumesux_application.dart` — the barrel is a bare
  `library;` with no `///` doc comment, and it re-exports the whole domain
  barrel.** The bible requires the barrel's doc comment to declare the package's
  error style; here nothing is declared, so a consumer cannot tell whether they
  receive tuples or exceptions. The extra `export 'package:resumesux_domain/
  resumesux_domain.dart'` also means this package's public surface silently
  includes another package's API and blurs which package owns the contract.

- **Deviation: `lib/` + `README.md` + (missing) `AGENTS.md` — the error style is
  never declared.** The bible: "ERROR STYLE IS DECLARED, LOUDLY" in the barrel doc
  comment, the README, and `AGENTS.md` on any deviation. This package presents
  unrun `TaskEither<Failure, T>` (not the default `Future<Either<Failure, T>>`),
  which is legitimate *only when declared*. The violation is the silence.

- **Deviation: the public seam is unrun `TaskEither<Failure, T>` everywhere.**
  Every repository/service contract method and every use-case `call()` returns a
  lazy `TaskEither`; the bible's default seam is `Future<Either<Failure, T>>` with
  `.run()` performed inside the layer. Consumers here must remember to `.run()`,
  which is exactly the laziness leak the bible's termination rule exists to stop.
  Flagged: a deliberate choice by this repo is plausible (the README example shows
  `.run()` at the call site), but it is undeclared.

- **Deviation: `README.md` — runnable code in the README, and an "Architecture"
  section that restates doctrine.** The bible: example code lives in tests first,
  `examples/` only for packages; never in READMEs/prose. The bible also bans
  restating rules/architecture in project docs (D.R.Y.). The README's Usage block
  references `UuidHandleGenerator()` and `ApplicantRepositoryImpl()` — neither
  exists in this package. Flagged: an onboarding README may warrant one snippet,
  but this one is wrong as written.

- **Deviation: `lib/src/failure.dart` — 17 failure classes in one file, flat
  hierarchy, not closed, no layer split.** The bible: one class per file; failure
  hierarchies are per-layer (domain vs datasource), defined in the domain package,
  closed with `sealed`/`final` leaves so `switch` is exhaustive; failures are
  value objects. Here a single `abstract class Failure` with non-`sealed`,
  non-`final` leaves mixes database, parsing, network, platform and environment
  failures in the *application* package, and the doc comment cites "the dartz
  package" while the code uses `fpdart`. No `props`/`Equatable`, so failures have
  identity equality only.

- **Deviation: `lib/src/repositories/**` — repository contracts live in the
  application package, not the domain package.** The bible: repository and
  datasource *contracts* live in the domain package; the application layer holds
  use cases. Everything repository-shaped here (including `BasicCrudContract`,
  `Transaction`, `UnitOfWork`) sits in the layer that is supposed to depend on the
  contracts. Flagged: this repo has no pub workspace, so the split may be an
  intentional simplification of Topology B.

- **Deviation: `lib/src/repositories/transaction.dart` and
  `lib/src/services/transaction.dart` — two different `abstract class Transaction`
  in one package.** Duplicate type name; `services/transaction.dart` is not
  reachable through the barrel (dead code), and any file importing both would
  collide. Flagged: the duplicate looks accidental rather than designed.

- **Deviation: `lib/src/repositories/transaction.dart` — `dynamic get db;`.** The
  bible's analyzer stance is `strict-raw-types`/no `dynamic`; this also leaks a
  datasource-shaped handle into the repository contract. `dynamic transaction`
  appears again on every `DatabaseService` method.

- **Deviation: `lib/src/repositories/basic_crud_contract.dart` — generic
  `BasicCrudContract<T, TH, TWH>` with cargo-shaped `item`/`twh` parameters, and
  it imports its own package barrel from inside `src/`.** The bible: params are
  discrete business params, never cargo objects; `src/` files should not import
  the package barrel (it hides the package's internal dependency graph and invites
  cycles). The contract also takes `Transaction? txn` instead of the doctrine's
  optional `IUnitOfWork? uow`. Flagged: the shared-CRUD shape is a reasonable DRY
  move; the parameter shape and the self-import are the questionable parts.

- **Deviation: `lib/src/repositories/unit_of_work.dart` — `UnitOfWork` exposes
  `commit()`/`rollback()` in addition to `run()`.** The bible's UnitOfWork contract
  is "write methods take optional `IUnitOfWork? uow`; transactional adapters wrap
  real transactions, others gracefully sink (NoOp/best-effort)". A public manual
  commit/rollback surface invites callers to manage transactions by hand. Flagged
  for review.

- **Deviation: `lib/src/services/database_service.dart` — a hand-rolled
  document-store abstraction (`Map<String, dynamic>` values, `dynamic`
  transactions) standing in for the sanctioned stores.** The bible: sqlite3 →
  drift, file store → sembast; adapters exist to isolate third-party libraries
  behind typed APIs. This interface re-invents the storage seam untyped, and
  `dynamic transaction` defeats the type system at exactly the boundary the bible
  wants typed. Flagged: this may be a deliberate "swap any store" design.

- **Deviation: `try`/`catch` and `throw` inside use cases** —
  `src/usecases/extract_jobreq_from_file_usecase.dart:85` (`throw failure` in a
  lazy callback) and `:159-165`; `src/usecases/yaml_digest/
  extract_applicant_from_digest_usecase.dart:46`, `:155-161`, `:196-202`;
  `src/usecases/yaml_digest/extract_gigs_from_digest_usecase.dart:96-102`;
  `src/usecases/yaml_digest/extract_assets_from_digest_usecase.dart:83-89`. The
  bible: "no `throw`, no `try/catch` (except `tryCatch` conversion at adapter
  boundaries)" inside the bulls-eye.

- **Deviation: `TaskEither.tryCatch` used inside use cases, not adapters** — four
  sites (`extract_jobreq_from_file_usecase.dart`, and all three
  `yaml_digest/extract_*`) wrap `dart:io`/`jsonDecode` failures inside the
  application layer. The bible: the adapter boundary is a *line*, and only the
  adapter may own the exception-conversion seam. Flagged: there are no adapters in
  this repo for the use cases to delegate to — the missing adapter package may be
  the real deviation.

- **Deviation: `dart:io` inside the application layer** —
  `src/usecases/yaml_digest/extract_applicant_from_digest_usecase.dart`,
  `extract_gigs_from_digest_usecase.dart` and `extract_assets_from_digest_usecase.dart`
  use `Directory`, `listSync`, `existsSync`, `readAsString` and
  `Platform.pathSeparator` directly. The application layer is supposed to be pure
  orchestration with no I/O (that is the datasource's job, reached through
  `FileRepository` — which this package already defines but these use cases
  bypass). `Platform.pathSeparator` also makes the use case non-portable.

- **Deviation: positional use-case parameters** —
  `GetApplicantUsecase.call(String handle)`, `GetJobReqUsecase.call(String handle)`
  (`get_jobreq_usercase.dart`), `GetApplicationUseCase.execute(String handle)`.
  The bible: named params always, sole exceptions a single positional `ref` or
  `message`. Flagged: `handle` is a plausible third exception the bible has not
  blessed.

- **Deviation: `src/usecases/get_application_usecase.dart` — `execute()` instead
  of `call()`, and no `///` docs on the class, constructor or method.** The bible
  names the entry point `call()` and requires terse `///` docs on declarations and
  public members (use cases especially). The file is also absent from the barrel.

- **Deviation: two `GetJobReqUsecase` classes** —
  `src/usecases/get_job_req_usecase.dart` and `src/usecases/get_jobreq_usercase.dart`
  declare the same class name with different behaviour (file+preprocess+retry vs
  plain `getByHandle`). Only the first is exported; the typo file
  (`usercase`) is unreachable dead code. The bible: one class per file, one
  meaning per name. Flagged: this looks like a rename that never completed.

- **Deviation: `Usecase` vs `UseCase` naming is inconsistent across the package**
  (`GetApplicantUsecase`, `GetConfigUsecase`, … vs `CreateJobReqUseCase`,
  `GetApplicationUseCase`, `ExtractApplicantFromDigestUseCase`). No doctrine rule
  picks a spelling, but the bible's "the signature is the documentation" spirit
  argues for one. Flagged so a human can pick a side.

- **Deviation: use cases that take domain cargo at construction** —
  `src/usecases/create_jobreq_usecase.dart` and
  `src/usecases/create_application_usecase.dart` require `applicant`, `jobReq`,
  `resume`, `coverLetter?`, `feedback?` (and `handleGenerator`) as constructor
  fields; several are never used (`CreateJobReqUseCase` ignores `applicant`,
  `resume`, `coverLetter`, `feedback`; `CreateApplicationUseCase.call({required
  String outputDir})` ignores `outputDir`). The bible: `call()` takes discrete
  business params; a use case holding half an application as state is the cargo
  smell in constructor form.

- **Deviation: `update` paths pass whole handle-wrapped entities** —
  `UpdateApplicantUsecase.call({required ApplicantWithHandle
  applicantWithHandle})`, `UpdateJobReqUsecase.call({required JobReqWithHandle …})`,
  and the generic `update({required TWH item})`. The bible's example is
  `deposit({required String id, required double amount})` — discrete business
  params. Flagged: passing an entity is arguably fine for a whole-aggregate
  update, which is why this is a deviation and not a bug.

- **Deviation: `Save*AiResponseUsecase` swallow failures** — all six
  (`save_asset_ai_response_usecase.dart`, `save_cover_letter_…`,
  `save_feedback_…`, `save_gig_…`, `save_job_req_…`, `save_resume_…`) end in
  `.orElse((_) => TaskEither.right(unit))`, discarding the `Left`. The bible:
  failure is a value that is displayed/decided at the UI ring — never silently
  replaced with success. Flagged: "saving AI responses is best-effort" may be the
  intent, but it is not stated anywhere.

- **Deviation: `src/usecases/generate_application_usecase.dart` threads a
  `required void Function(String) progress` callback through the core and
  sequences effects via `TaskEither.right(unit).map((_) => progress(...))`.**
  The application layer is orchestration, not a UI-effect channel; the bible also
  recommends Do-notation over deep `flatMap` chains. Related: `jobReqId =
  jobReq.hashCode.toString()` — a persistence key derived from `Object.hashCode`,
  which is not stable across runs/isolates.

- **Deviation: AI-generation use cases write side effects inside `.map()`** —
  `GenerateResumeUsecase`, `GenerateCoverLetterUsecase` and
  `GenerateFeedbackUsecase` take an optional repository and call
  `setLastAiResponse(...)` inside the `map` callback. A read-then-write seam inside
  a generation use case, outside any UnitOfWork, is the shape the bible's
  persistence doctrine (`IUnitOfWork? uow`, adapters wrap real transactions)
  exists to make explicit.

- **Deviation: `GetJobReqUsecase` re-reads the file it just processed and
  discards a value mid-chain** — `src/usecases/get_job_req_usecase.dart` maps
  `JobReqWithHandle` to `unit` and then re-reads the same path through
  `FileRepository` to rebuild the job req. The bible's laziness pitfall note
  ("thread values through the chain") points at exactly this pattern. Flagged:
  the retry-after-preprocess flow may genuinely need the second read.

- **Deviation: `test`/`mocktail` are declared but `shouldly` is absent.** The
  bible's assertion library is `shouldly` ("should be"), with `mocktail` mocks at
  the use-case seam only. This package has neither tests nor a `shouldly`
  dependency, so the doctrine's testing stack is only half-wired. Flagged: with
  zero tests, adding `shouldly` before the first test is cheap.

- **Deviation: no pub workspace / single flat package.** The bible's Topology B is
  a core repo of `*_domain` / `*_usecases` / `*_datasource_*` packages plus a
  separate UI repo. This repo is a single package that mixes use cases, repository
  contracts, service contracts and failures, with no workspace and no adapter
  package. Flagged: the separation may be intentional for this repo's size.
