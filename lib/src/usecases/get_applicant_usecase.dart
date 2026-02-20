import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for retrieving applicant information from database
class GetApplicantUsecase {
  final ApplicantRepository applicantRepository;

  /// Creates a new instance of [GetApplicantUsecase].
  GetApplicantUsecase({required this.applicantRepository});

  /// get the applicant record from database
  TaskEither<Failure, Applicant> call(ApplicantHandle handle) {
    return applicantRepository.getByHandle(handle: handle);
  }
}
