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

## License

Apache License 2.0
