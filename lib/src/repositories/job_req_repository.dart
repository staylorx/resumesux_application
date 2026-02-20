import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Repository for job requirement-related operations.
abstract class JobReqRepository implements DocRepository {
  /// Creates a new job requirement.
  TaskEither<Failure, JobReq> createJobReq({required JobReq jobReq});

  /// Retrieves a job requirement from the given path.
  TaskEither<Failure, JobReq> getJobReq({required String path});

  /// Updates an existing job requirement.
  TaskEither<Failure, Unit> updateJobReq({required JobReq jobReq});

  /// Retrieves the last AI response as JSON string.
  @override
  String? getLastAiResponseJson();

  /// Saves the AI response JSON for a job requirement to the database.
  @override
  TaskEither<Failure, Unit> saveAiResponse({
    required String aiResponseJson,
    required String jobReqId,
    String? content,
  });

  TaskEither<Failure, Unit> save({
    required JobReqHandle handle,
    required JobReq jobReq,
  });
  TaskEither<Failure, JobReq> getByHandle({required JobReqHandle handle});
  TaskEither<Failure, List<JobReqWithHandle>> getAll(); // For listing
  TaskEither<Failure, Unit> remove({required JobReqHandle handle});
}
