import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/application_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for retrieving an application by handle.
class GetApplicationUseCase {
  /// The repository used to retrieve the application.
  final ApplicationRepository repository;

  /// Creates a [GetApplicationUseCase] with the given repository.
  GetApplicationUseCase(this.repository);

  /// Retrieves the application with the given handle.
  TaskEither<Failure, ApplicationWithHandle> execute(String handle) {
    return repository.getByHandle(handle: handle);
  }
}
