import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for retrieving a job requirement, with preprocessing if needed.
class GetJobReqUsecase {
  final JobReqRepository jobReqRepository;
  final ExtractJobReqFromFileUsecase createJobReqUsecase;
  final FileRepository fileRepository;

  /// Creates a new instance of [GetJobReqUsecase].
  GetJobReqUsecase({
    required this.jobReqRepository,
    required this.createJobReqUsecase,
    required this.fileRepository,
  });

  /// Retrieves the job requirement for the given path.
  ///
  /// If parsing fails, preprocesses the job requirement and retries.
  ///
  /// Parameters:
  /// - [path]: Path to the job requirement file.
  ///
  /// Returns: [TaskEither<Failure, JobReqWithHandle>] the job requirement with handle or a failure.
  TaskEither<Failure, JobReqWithHandle> call({required String path}) {
    return TaskEither.fromEither(fileRepository.readFile(path: path)).flatMap((content) {
      return jobReqRepository.createJobReqFromContent(
        content: content,
        path: path,
      ).orElse((failure) {
        if (failure is ParsingFailure) {
          return createJobReqUsecase(
            path: path,
          ).map((jobReqWithHandle) => unit).flatMap((_) {
            return TaskEither.fromEither(fileRepository.readFile(path: path)).flatMap((content) {
              return jobReqRepository.createJobReqFromContent(
                content: content,
                path: path,
              );
            });
          });
        }
        return TaskEither.left(failure);
      });
    });
  }
}
