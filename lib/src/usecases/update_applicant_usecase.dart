import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/applicant_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for updating an applicant
class UpdateApplicantUsecase {
  /// The repository used to update the applicant.
  final ApplicantRepository applicantRepository;

  /// Creates a new instance of [UpdateApplicantUsecase].
  UpdateApplicantUsecase({required this.applicantRepository});

  /// Update the applicant
  TaskEither<Failure, ApplicantWithHandle> call({
    required ApplicantWithHandle applicantWithHandle,
  }) {
    return applicantRepository.update(item: applicantWithHandle);
  }
}
