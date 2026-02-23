import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for retrieving job req from database
class GetJobReqUsecase {
  final JobReqRepository repository;

  /// gets the instance of [GetJobReqUsecase].
  GetJobReqUsecase({required this.repository});

  /// Returns: [TaskEither<Failure, JobReqWithHandle>] containing the enriched job req or a failure.
  TaskEither<Failure, JobReqWithHandle> call(String handle) {
    return repository.getByHandle(handle: handle);
  }
}
