import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for creating a new applicant by importing from digest
class CreateApplicantUseCase {
  final ApplicantRepository repository;
  final HandleGenerator handleGenerator;

  CreateApplicantUseCase({
    required this.repository,
    required this.handleGenerator,
  });

  TaskEither<Failure, ApplicantHandle> call({
    required Applicant applicant,
    required String digestPath,
  }) {
    final handle = handleGenerator.generateApplicantHandle();
    return repository
        .importDigest(
          applicant: applicant,
          digestPath: digestPath,
        )
        .flatMap((updatedApplicant) => repository.save(
              handle: handle,
              applicant: updatedApplicant,
            ))
        .map((_) => handle);
  }
}
