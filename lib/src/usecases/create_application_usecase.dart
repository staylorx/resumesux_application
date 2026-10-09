import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/application_repository.dart';
import 'package:resumesux_application/src/services/handle_generator.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for creating a new application
class CreateApplicationUseCase {
  /// The repository used to persist the created application.
  final ApplicationRepository repository;

  /// The applicant associated with the application.
  final Applicant applicant;

  /// The job requirement associated with the application.
  final JobReq jobReq;

  /// The resume associated with the application.
  final Resume resume;

  /// An optional cover letter associated with the application.
  final CoverLetter? coverLetter;

  /// An optional feedback associated with the application.
  final Feedback? feedback;

  /// Generates the handle for the new application.
  final HandleGenerator handleGenerator;

  /// Creates a [CreateApplicationUseCase] with the given dependencies.
  CreateApplicationUseCase({
    required this.repository,
    required this.applicant,
    required this.jobReq,
    required this.resume,
    required this.handleGenerator,
    this.coverLetter,
    this.feedback,
  });

  /// Creates a new application based on the configured applicant, job
  /// requirement, resume, and optional cover letter and feedback, and returns
  /// its generated handle.
  TaskEither<Failure, ApplicationHandle> call({required String outputDir}) {
    final handle = handleGenerator.generateApplicationHandle();
    final newApplication = Application(
      applicant: applicant,
      jobReq: jobReq,
      resume: resume,
      coverLetter: coverLetter,
      feedback: feedback,
    );
    return repository.create(item: newApplication).map((_) => handle);
  }
}
