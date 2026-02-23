import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';
import 'package:resumesux_application/src/repositories/basic_crud_contract.dart';

/// Repository for job requirement-related operations.
abstract class JobReqRepository
    implements
        DocumentRepository,
        BasicCrudContract<JobReq, String, JobReqWithHandle> {
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

  /// Retrieves a job requirement from the given path.
  TaskEither<Failure, JobReq> getJobReq({required String path});
}
