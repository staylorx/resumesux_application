import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/repositories/business/job_req_repository.dart';
import 'package:resumesux_application/src/services/handle_generator.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for creating a new jobrec in the database
class CreateJobReqUseCase {
  /// The repository used to persist the created job requirement.
  final JobReqRepository repository;

  /// The applicant associated with the job requirement.
  final Applicant applicant;

  /// The job requirement to be created.
  final JobReq jobReq;

  /// The resume associated with the job requirement.
  final Resume resume;

  /// An optional cover letter associated with the job requirement.
  final CoverLetter? coverLetter;

  /// An optional feedback associated with the job requirement.
  final Feedback? feedback;

  /// Generates the handle for the new job requirement.
  final HandleGenerator handleGenerator;

  /// Creates a [CreateJobReqUseCase] with the given dependencies.
  CreateJobReqUseCase({
    required this.repository,
    required this.applicant,
    required this.jobReq,
    required this.resume,
    required this.handleGenerator,
    this.coverLetter,
    this.feedback,
  });

  /// Creates a new job requirement from the given title and content and
  /// returns its generated handle.
  TaskEither<Failure, JobReqHandle> call({
    required String title,
    required String content,
    String? contentType,
  }) {
    final handle = handleGenerator.generateJobReqHandle();
    final jobReq = JobReq(
      title: title,
      content: content,
      contentType: contentType ?? 'text/markdown',
    );
    return repository.create(item: jobReq).map((_) => handle);
  }
}
