import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/job_req_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for updating an existing job requirement.
class UpdateJobReqUsecase {
  /// The repository used to update the job requirement.
  final JobReqRepository jobReqRepository;

  /// Creates a new instance of [UpdateJobReqUsecase].
  UpdateJobReqUsecase({required this.jobReqRepository});

  /// Updates the given job requirement.
  ///
  /// Parameters:
  /// - [jobReqWithHandle]: The job requirement with handle to update.
  ///
  /// Returns: [TaskEither<Failure, JobReqWithHandle>] the updated job req with handle or a failure.
  TaskEither<Failure, JobReqWithHandle> call({
    required JobReqWithHandle jobReqWithHandle,
  }) {
    return jobReqRepository.update(item: jobReqWithHandle);
  }
}
