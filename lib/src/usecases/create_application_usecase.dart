import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/application_repository.dart';
import 'package:resumesux_application/src/services/handle_generator.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for creating a new application
class CreateApplicationUseCase {
  final ApplicationRepository repository;
  final Applicant applicant;
  final JobReq jobReq;
  final Resume resume;
  final CoverLetter? coverLetter;
  final Feedback? feedback;
  final HandleGenerator handleGenerator;

  CreateApplicationUseCase({
    required this.repository,
    required this.applicant,
    required this.jobReq,
    required this.resume,
    required this.handleGenerator,
    this.coverLetter,
    this.feedback,
  });

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
