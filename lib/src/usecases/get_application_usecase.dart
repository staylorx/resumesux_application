import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/application_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

class GetApplicationUseCase {
  final ApplicationRepository repository;

  GetApplicationUseCase(this.repository);

  TaskEither<Failure, ApplicationWithHandle> execute(String handle) {
    return repository.getByHandle(handle: handle);
  }
}
