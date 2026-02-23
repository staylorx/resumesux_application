import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Repository for saving cover letter documents.
abstract class CoverLetterRepository implements DocRepository {
  /// Saves a cover letter to a file in the specified output directory and to the database.
  ///
  /// Requires jobTitle for file naming and jobReqId for DB.
  TaskEither<Failure, Unit> saveCoverLetter({
    required CoverLetter coverLetter,
    required String outputDir,
    required String jobTitle,
    required String jobReqId,
  });

  /// Saves the AI response JSON for a cover letter to the database.
  @override
  TaskEither<Failure, Unit> saveAiResponse({
    required String aiResponseJson,
    required String jobReqId,
    String? content,
  });
}
