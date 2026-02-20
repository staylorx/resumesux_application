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
  /// - [jobReq]: The job requirement to update.
  ///
  /// Returns: [TaskEither<Failure, Unit>] success or a failure.
  TaskEither<Failure, Unit> call({required JobReq jobReq}) {
    return jobReqRepository.updateJobReq(jobReq: jobReq);
  }
}
