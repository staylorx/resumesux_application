import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for updating an applicant
class UpdateApplicantUsecase {
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
