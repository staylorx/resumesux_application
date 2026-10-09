import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/applicant_repository.dart';

/// Use case for removing an applicant
class RemoveApplicantUsecase {
  final ApplicantRepository applicantRepository;

  /// Creates a new instance of [RemoveApplicantUsecase].
  RemoveApplicantUsecase({required this.applicantRepository});

  /// Remove the applicant
  TaskEither<Failure, Unit> call({required String handle}) {
    return applicantRepository.deleteByHandle(handle: handle);
  }
}
