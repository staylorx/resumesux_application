import 'package:resumesux_domain/resumesux_domain.dart';

/// Abstract service for generating unique handles for domain entities.
abstract class HandleGenerator {
  /// Generates a unique ApplicantHandle.
  ApplicantHandle generateApplicantHandle();

  /// Generates a unique ApplicationHandle.
  ApplicationHandle generateApplicationHandle();

  /// Generates a unique JobReqHandle.
  JobReqHandle generateJobReqHandle();
}