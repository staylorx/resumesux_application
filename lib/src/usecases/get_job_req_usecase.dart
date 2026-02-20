import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for retrieving a job requirement, with preprocessing if needed.
class GetJobReqUsecase {
  final JobReqRepository jobReqRepository;
  final ExtractJobReqFromFileUsecase createJobReqUsecase;

  /// Creates a new instance of [GetJobReqUsecase].
  GetJobReqUsecase({
    required this.jobReqRepository,
    required this.createJobReqUsecase,
  });

  /// Retrieves the job requirement for the given path.
  ///
  /// If parsing fails, preprocesses the job requirement and retries.
  ///
  /// Parameters:
  /// - [path]: Path to the job requirement file.
  ///
  /// Returns: [TaskEither<Failure, JobReq>] the job requirement or a failure.
  TaskEither<Failure, JobReq> call({required String path}) {
    return jobReqRepository.getJobReq(path: path).orElse((failure) {
      if (failure is ParsingFailure) {
        return createJobReqUsecase(path: path).flatMap((_) {
          return jobReqRepository.getJobReq(path: path);
        });
      }
      return TaskEither.left(failure);
    });
  }
}
