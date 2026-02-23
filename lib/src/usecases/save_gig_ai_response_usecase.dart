import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for saving AI responses for gigs to the database.
class SaveGigAiResponseUsecase {
  final GigRepository gigRepository;

  /// Creates a new instance of [SaveGigAiResponseUsecase].
  SaveGigAiResponseUsecase({required this.gigRepository});

  /// Saves AI responses for gigs.
  ///
  /// Parameters:
  /// - [jobReqId]: The job requirement ID.
  ///
  /// Returns: [TaskEither<Failure, Unit>] indicating success or failure.
  TaskEither<Failure, Unit> call({required String jobReqId}) {
    final gigAiResponseJson = gigRepository.getLastAiResponsesJson();
    if (gigAiResponseJson != null) {
      return gigRepository
          .saveAiResponse(aiResponseJson: gigAiResponseJson, jobReqId: jobReqId)
          .orElse((_) => TaskEither.right(unit));
    }
    return TaskEither.right(unit);
  }
}
