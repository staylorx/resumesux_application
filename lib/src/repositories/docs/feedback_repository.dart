import 'package:fpdart/fpdart.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../../failure.dart';

/// Repository for saving feedback documents.
abstract class FeedbackRepository {
  /// Retrieves the last AI response as JSON string.
  String? getLastAiResponseJson();

  /// Sets the last AI response.
  void setLastAiResponse(Map<String, dynamic> response);

  /// Saves a feedback to a file in the specified output directory and to the database.
  TaskEither<Failure, Unit> saveFeedback({
    required Feedback feedback,
    required String outputDir,
    required String jobReqId,
  });

  /// Saves the AI response JSON for feedback to the database.
  TaskEither<Failure, Unit> saveAiResponse({
    required String aiResponseJson,
    required String content,
    required String jobReqId,
  });
}
