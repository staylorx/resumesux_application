import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for saving AI responses for cover letter to the database.
class SaveCoverLetterAiResponseUsecase {
  final CoverLetterRepository? coverLetterRepository;

  /// Creates a new instance of [SaveCoverLetterAiResponseUsecase].
  SaveCoverLetterAiResponseUsecase({this.coverLetterRepository});

  /// Saves AI response for cover letter.
  ///
  /// Parameters:
  /// - [jobReqId]: The job requirement ID.
  ///
  /// Returns: [TaskEither<Failure, Unit>] indicating success or failure.
  TaskEither<Failure, Unit> call({required String jobReqId}) {
    final coverLetterAiResponseJson = coverLetterRepository
        ?.getLastAiResponseJson();
    if (coverLetterAiResponseJson != null && coverLetterRepository != null) {
      return coverLetterRepository!
          .saveAiResponse(
            aiResponseJson: coverLetterAiResponseJson,
            jobReqId: jobReqId,
            content: '', // Content is in the JSON
          )
          .orElse((_) => TaskEither.right(unit));
    }
    return TaskEither.right(unit);
  }
}
