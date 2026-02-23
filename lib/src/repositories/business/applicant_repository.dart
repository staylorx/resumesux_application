import 'package:fpdart/fpdart.dart';
import 'package:resumesux_domain/resumesux_domain.dart';
import '../../failure.dart';

/// Repository for applicant-related operations.
abstract class ApplicantRepository {
  TaskEither<Failure, Unit> save({
    required ApplicantHandle handle,
    required Applicant applicant,
  });
  TaskEither<Failure, Applicant> getByHandle({required ApplicantHandle handle});
  TaskEither<Failure, List<ApplicantWithHandle>> getAll(); // For listing
  TaskEither<Failure, Unit> remove({required ApplicantHandle handle});
}
