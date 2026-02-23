import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for creating a new jobrec in the database
class CreateJobReqUseCase {
  final JobReqRepository repository;
  final Applicant applicant;
  final JobReq jobReq;
  final Resume resume;
  final CoverLetter? coverLetter;
  final Feedback? feedback;
  final HandleGenerator handleGenerator;

  CreateJobReqUseCase({
    required this.repository,
    required this.applicant,
    required this.jobReq,
    required this.resume,
    required this.handleGenerator,
    this.coverLetter,
    this.feedback,
  });

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
