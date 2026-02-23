import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/repositories/basic_crud_contract.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../../failure.dart';

/// Repository for gig-related operations.
abstract class GigRepository
    implements BasicCrudContract<Gig, String, GigWithHandle> {
  /// Retrieves the last AI responses as JSON string.
  String? getLastAiResponsesJson();

  /// Saves the AI responses JSON for gigs to the database.
  TaskEither<Failure, Unit> saveAiResponse({
    required String aiResponseJson,
    required String jobReqId,
  });
}
