import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

class GetApplicationUseCase {
  final ApplicationRepository repository;

  GetApplicationUseCase(this.repository);

  TaskEither<Failure, Application> execute(ApplicationHandle handle) {
    return repository.getByHandle(handle: handle);
  }
}
