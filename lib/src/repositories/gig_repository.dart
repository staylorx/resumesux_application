import 'package:fpdart/fpdart.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../failure.dart';

/// Repository for gig-related operations.
abstract class GigRepository {
  /// Retrieves all gigs.
  TaskEither<Failure, List<Gig>> getAllGigs();

  TaskEither<Failure, List<GigWithHandle>> getAll(); // For listing

  /// Retrieves the last AI responses as JSON string.
  String? getLastAiResponsesJson();

  /// Saves the AI responses JSON for gigs to the database.
  TaskEither<Failure, Unit> saveAiResponse({
    required String aiResponseJson,
    required String jobReqId,
  });
}
