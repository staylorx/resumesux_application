# ResumesUX Application Layer

Contracts and use cases for ResumesUX clean architecture. This package provides the application layer with functional error handling using `fpdart`'s `TaskEither` type, repository abstractions, and use case implementations.

## Overview

The application layer orchestrates domain logic using functional programming patterns. All asynchronous operations return `TaskEither<Failure, T>` to ensure errors are explicitly handled and flow through the pipeline.

## Key Features

- **Functional error handling**: All repository and service methods return `TaskEither<Failure, T>`
- **Use case implementations**: Business logic encapsulated in reusable use case classes
- **Repository contracts**: Abstract interfaces for data access (applicants, applications, job requirements, etc.)
- **AI service integration**: Abstract AI service with provider support (LM Studio, Ollama, etc.)
- **Handle generation**: Abstract `HandleGenerator` for creating unique entity identifiers
- **Failure hierarchy**: Structured failure types for different error scenarios

## Architecture

- **Repositories**: Abstract data access (`ApplicantRepository`, `JobReqRepository`, etc.)
- **Services**: Abstract external services (`AiService`, `AiServiceFactory`, `HandleGenerator`)
- **Use Cases**: Application-specific business logic (`CreateApplicantUseCase`, `GenerateApplicationUsecase`, etc.)
- **Failures**: Error types extending `Failure` for different failure modes

## Usage

```dart
// Example: Creating an applicant with handle generation
final handleGenerator = UuidHandleGenerator();
final repository = ApplicantRepositoryImpl();
final useCase = CreateApplicantUseCase(
  repository: repository,
  handleGenerator: handleGenerator,
);

final result = await useCase(
  applicant: applicant,
  digestPath: '/path/to/digest',
).run();

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (handle) => print('Created applicant with handle: $handle'),
);
```

## Dependencies

- `fpdart`: Functional programming utilities
- `resumesux_domain`: Domain entities and value objects

## Testing

Run tests with `dart test`. The test suite includes unit tests for use cases and repository contracts.

### Fitness screening (persona → job)

`tool/fitness/run_fitness.dart` scores every persona fixture against every job fixture and reports per-pair pass-rates, accuracy, and false-accepts. It is the guardrail for the "reject a heavy-equipment operator for a data-scientist job (and vice versa)" requirement.

Run the full matrix (default model, 1 run per pair):

```sh
dart run tool/fitness/run_fitness.dart --provider ollama
# --runs N         repeat each pair N times to measure variance
# --job <substr>   restrict to one job column (e.g. "Data Scientist")
# --persona <substr> restrict to matching persona rows
# --model <name>   override the provider default model
# --out <path>     write a JSON report (per-pair pass-rates + totals)
```

Default screening model: `qwen3.5:9b` (config.yaml → `providers.ollama.models`; fast, and strict enough for near-miss rejection). Other local models stay selectable via `--model`.

**Verified result (qwen3.5:9b, 2 runs × 48 pairs = 96 verdicts):** 100.0% accuracy, 0 false-accepts, 0 parse failures. All 6 diagonal fits accepted; all 42 mismatches rejected; every cross-case (data-scientist ⇄ heavy-equipment, line-cook, nurse, teacher, backend, bootcamp, enthusiast → both) rejected. `ML Bootcamp Grad` is now handled correctly by the strict weak-qualifier rule in `FitnessScorer` (basic/entry-level skills do not count as a fit).

The generated-application quality gate lives in `GradeScorer` (`tool/fitness/grade_content.dart`): it grades whether a produced application concretely covers a job's required skills (fit threshold = strict majority), and returns per-skill covered/missing.

## License

Apache License 2.0
