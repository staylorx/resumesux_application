import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

class GetApplicationUseCase {
  final ApplicationRepository repository;

  GetApplicationUseCase(this.repository);

  TaskEither<Failure, ApplicationWithHandle> execute(String handle) {
    return repository.getByHandle(handle: handle);
  }
}
