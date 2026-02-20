import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

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
