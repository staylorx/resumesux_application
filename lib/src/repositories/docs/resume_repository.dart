import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Repository for saving resume documents.
abstract class ResumeRepository implements DocRepository {
  /// Saves a resume to a file in the specified output directory and to the database.
  ///
  /// Requires jobTitle for file naming and jobReqId for DB.
  TaskEither<Failure, Unit> saveResume({
    required Resume resume,
    required String outputDir,
    required String jobTitle,
    required String jobReqId,
  });

  /// Saves the AI response JSON for a resume to the database.
  @override
  TaskEither<Failure, Unit> saveAiResponse({
    required String aiResponseJson,
    required String jobReqId,
    String? content,
  });
}
