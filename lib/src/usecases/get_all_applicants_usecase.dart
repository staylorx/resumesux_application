import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/applicant_repository.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for retrieving all applicants
class GetAllApplicantsUsecase {
  final ApplicantRepository applicantRepository;

  /// Creates a new instance of [GetAllApplicantsUsecase].
  GetAllApplicantsUsecase({required this.applicantRepository});

  /// Get all applicants
  TaskEither<Failure, List<ApplicantWithHandle>> call() {
    return applicantRepository.getAll();
  }
}
