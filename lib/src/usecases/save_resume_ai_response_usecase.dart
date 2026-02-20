import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for saving AI responses for resume to the database.
class SaveResumeAiResponseUsecase {
  final ResumeRepository? resumeRepository;

  /// Creates a new instance of [SaveResumeAiResponseUsecase].
  SaveResumeAiResponseUsecase({this.resumeRepository});

  /// Saves AI response for resume.
  ///
  /// Parameters:
  /// - [jobReqId]: The job requirement ID.
  ///
  /// Returns: [TaskEither<Failure, Unit>] indicating success or failure.
  TaskEither<Failure, Unit> call({required String jobReqId}) {
    final resumeAiResponseJson = resumeRepository?.getLastAiResponseJson();
    if (resumeAiResponseJson != null && resumeRepository != null) {
      return resumeRepository!.saveAiResponse(
        aiResponseJson: resumeAiResponseJson,
        jobReqId: jobReqId,
        content: '', // Content is in the JSON
      ).orElse((_) => TaskEither.right(unit));
    }
    return TaskEither.right(unit);
  }
}
