import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for updating an existing job requirement.
class UpdateJobReqUsecase {
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
