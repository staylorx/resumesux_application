import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for retrieving job req from database
class GetJobReqUsecase {
  final JobReqRepository repository;

  /// gets the instance of [GetJobReqUsecase].
  GetJobReqUsecase({required this.repository});

  /// Returns: [TaskEither<Failure, JobReq>] containing the enriched applicant or a failure.
  TaskEither<Failure, JobReq> call(JobReqHandle handle) {
    return repository.getByHandle(handle: handle);
  }
}
