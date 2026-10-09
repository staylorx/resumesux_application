import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/applicant_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for retrieving applicant information from database
class GetApplicantUsecase {
  final ApplicantRepository applicantRepository;

  /// Creates a new instance of [GetApplicantUsecase].
  GetApplicantUsecase({required this.applicantRepository});

  /// get the applicant record from database
  TaskEither<Failure, ApplicantWithHandle> call(String handle) {
    return applicantRepository.getByHandle(handle: handle);
  }
}
