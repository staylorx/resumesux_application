import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for saving AI responses for job requirements to the database.
class SaveJobReqAiResponseUsecase {
  final JobReqRepository jobReqRepository;

  /// Creates a new instance of [SaveJobReqAiResponseUsecase].
  SaveJobReqAiResponseUsecase({
    required this.jobReqRepository,
  });

  /// Saves AI response for the job requirement.
  ///
  /// Parameters:
  /// - [jobReqId]: The job requirement ID.
  ///
  /// Returns: [TaskEither<Failure, Unit>] indicating success or failure.
  TaskEither<Failure, Unit> call({required String jobReqId}) {
    final aiResponseJson = jobReqRepository.getLastAiResponseJson();
    if (aiResponseJson != null) {
      return jobReqRepository.saveAiResponse(
        aiResponseJson: aiResponseJson,
        jobReqId: jobReqId,
      ).orElse((_) => TaskEither.right(unit));
    }
    return TaskEither.right(unit);
  }
}
