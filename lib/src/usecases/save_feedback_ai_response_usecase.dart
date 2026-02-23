import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for saving AI responses for feedback to the database.
class SaveFeedbackAiResponseUsecase {
  final FeedbackRepository? feedbackRepository;

  /// Creates a new instance of [SaveFeedbackAiResponseUsecase].
  SaveFeedbackAiResponseUsecase({this.feedbackRepository});

  /// Saves AI response for feedback.
  ///
  /// Parameters:
  /// - [jobReqId]: The job requirement ID.
  ///
  /// Returns: [TaskEither<Failure, Unit>] indicating success or failure.
  TaskEither<Failure, Unit> call({required String jobReqId}) {
    final feedbackAiResponseJson = feedbackRepository?.getLastAiResponseJson();
    if (feedbackAiResponseJson != null && feedbackRepository != null) {
      return feedbackRepository!
          .saveAiResponse(
            aiResponseJson: feedbackAiResponseJson,
            jobReqId: jobReqId,
            content: '', // Content is in the JSON
          )
          .orElse((_) => TaskEither.right(unit));
    }
    return TaskEither.right(unit);
  }
}
