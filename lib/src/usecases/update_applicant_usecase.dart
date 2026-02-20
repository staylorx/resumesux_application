import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for updating an applicant
class UpdateApplicantUsecase {
  final ApplicantRepository applicantRepository;

  /// Creates a new instance of [UpdateApplicantUsecase].
  UpdateApplicantUsecase({required this.applicantRepository});

  /// Update the applicant
  TaskEither<Failure, Unit> call({
    required ApplicantHandle handle,
    required Applicant applicant,
  }) {
    return applicantRepository.save(
      handle: handle,
      applicant: applicant,
    );
  }
}
