import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for removing an applicant
class RemoveApplicantUsecase {
  final ApplicantRepository applicantRepository;

  /// Creates a new instance of [RemoveApplicantUsecase].
  RemoveApplicantUsecase({required this.applicantRepository});

  /// Remove the applicant
  TaskEither<Failure, Unit> call({required ApplicantHandle handle}) {
    return applicantRepository.remove(handle: handle);
  }
}
