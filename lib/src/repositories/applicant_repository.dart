import 'package:fpdart/fpdart.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../failure.dart';

/// Repository for applicant-related operations.
abstract class ApplicantRepository {
  /// Imports gigs and assets from the specified digest path and associates them with the applicant.
  TaskEither<Failure, Applicant> importDigest({
    required Applicant applicant,
    required String digestPath,
  });

  TaskEither<Failure, Unit> save({
    required ApplicantHandle handle,
    required Applicant applicant,
  });
  TaskEither<Failure, Applicant> getByHandle({
    required ApplicantHandle handle,
  });
  TaskEither<Failure, List<ApplicantWithHandle>> getAll(); // For listing
  TaskEither<Failure, Unit> remove({required ApplicantHandle handle});
}
