import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/job_req_repository.dart';
import 'package:resumesux_application/src/repositories/file_repository.dart';
import 'package:resumesux_application/src/usecases/extract_jobreq_from_file_usecase.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for retrieving a job requirement, with preprocessing if needed.
class GetJobReqUsecase {
  /// The repository used to retrieve job requirements.
  final JobReqRepository jobReqRepository;

  /// The use case used to create a job requirement when preprocessing is needed.
  final ExtractJobReqFromFileUsecase createJobReqUsecase;

  /// The repository used to read job requirement files.
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
    return TaskEither.fromEither(fileRepository.readFile(path: path)).flatMap((
      content,
    ) {
      return jobReqRepository
          .createJobReqFromContent(content: content, path: path)
          .orElse((failure) {
            if (failure is ParsingFailure) {
              return createJobReqUsecase(
                path: path,
              ).map((jobReqWithHandle) => unit).flatMap((_) {
                return TaskEither.fromEither(
                  fileRepository.readFile(path: path),
                ).flatMap((content) {
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
