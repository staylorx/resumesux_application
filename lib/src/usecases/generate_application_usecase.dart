import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/src/failure.dart';
import 'package:resumesux_application/src/usecases/generate_cover_letter_usecase.dart';
import 'package:resumesux_application/src/usecases/generate_feedback_usecase.dart';
import 'package:resumesux_application/src/usecases/generate_resume_usecase.dart';
import 'package:resumesux_application/src/usecases/save_asset_ai_response_usecase.dart';
import 'package:resumesux_application/src/usecases/save_cover_letter_ai_response_usecase.dart';
import 'package:resumesux_application/src/usecases/save_feedback_ai_response_usecase.dart';
import 'package:resumesux_application/src/usecases/save_gig_ai_response_usecase.dart';
import 'package:resumesux_application/src/usecases/save_job_req_ai_response_usecase.dart';
import 'package:resumesux_application/src/usecases/save_resume_ai_response_usecase.dart';
import 'package:resumesux_domain/resumesux_domain.dart';

/// Use case for generating a complete job application including resume, cover letter, and feedback.
class GenerateApplicationUsecase {
  /// The use case that generates a resume for the application.
  final GenerateResumeUsecase generateResumeUsecase;

  /// The use case that generates a cover letter for the application.
  final GenerateCoverLetterUsecase generateCoverLetterUsecase;

  /// The use case that generates feedback for the application.
  final GenerateFeedbackUsecase generateFeedbackUsecase;

  /// Saves the job requirement AI response produced during generation.
  final SaveJobReqAiResponseUsecase saveJobReqAiResponseUsecase;

  /// Saves the gig AI response produced during generation.
  final SaveGigAiResponseUsecase saveGigAiResponseUsecase;

  /// Saves the asset AI response produced during generation.
  final SaveAssetAiResponseUsecase saveAssetAiResponseUsecase;

  /// Saves the resume AI response produced during generation.
  final SaveResumeAiResponseUsecase saveResumeAiResponseUsecase;

  /// Saves the cover letter AI response produced during generation.
  final SaveCoverLetterAiResponseUsecase saveCoverLetterAiResponseUsecase;

  /// Saves the feedback AI response produced during generation.
  final SaveFeedbackAiResponseUsecase saveFeedbackAiResponseUsecase;

  /// Creates a new instance of [GenerateApplicationUsecase].
  GenerateApplicationUsecase({
    required this.generateResumeUsecase,
    required this.generateCoverLetterUsecase,
    required this.generateFeedbackUsecase,
    required this.saveJobReqAiResponseUsecase,
    required this.saveGigAiResponseUsecase,
    required this.saveAssetAiResponseUsecase,
    required this.saveResumeAiResponseUsecase,
    required this.saveCoverLetterAiResponseUsecase,
    required this.saveFeedbackAiResponseUsecase,
  });

  /// Generates an application for the given job requirement.
  ///
  /// This method orchestrates the generation of a resume, optional cover letter,
  /// and optional feedback based on the provided parameters.
  ///
  /// Parameters:
  /// - [jobReq]: The job requirement entity.
  /// - [applicant]: The applicant information.
  /// - [config]: The application configuration.
  /// - [prompt]: The prompt for AI generation.
  /// - [includeCover]: Whether to include a cover letter.
  /// - [includeFeedback]: Whether to include feedback.
  /// - [tone]: Tone parameter for feedback generation (0.0 = brutal, 1.0 = enthusiastic).
  /// - [length]: Length parameter for feedback generation (0.0 = brief, 1.0 = detailed).
  /// - [progress]: Callback function to report progress messages.
  ///
  /// Returns: [TaskEither<Failure, Application>] the generated application or a failure.
  TaskEither<Failure, Application> call({
    required JobReq jobReq,
    required Applicant applicant,
    required Config config,
    required String prompt,
    required bool includeCover,
    required bool includeFeedback,
    double tone = 0.5,
    double length = 0.5,
    required void Function(String) progress,
  }) {
    return TaskEither<Failure, Unit>.right(unit)
        .map(
          (_) => progress(
            'Starting application generation for job: ${jobReq.title}',
          ),
        )
        .flatMap((_) {
          progress('Generating resume');
          return generateResumeUsecase(
            jobReq: jobReq,
            applicant: applicant,
            prompt: prompt,
          );
        })
        .flatMap((resume) {
          progress('Resume generated successfully');

          final coverLetterTask = includeCover
              ? TaskEither<Failure, Unit>.right(unit)
                    .map((_) => progress('Generating cover letter'))
                    .flatMap(
                      (_) => generateCoverLetterUsecase(
                        jobReq: jobReq,
                        resume: resume,
                        applicant: applicant,
                        prompt: prompt,
                      ),
                    )
                    .map((coverLetter) {
                      progress('Cover letter generated successfully');
                      return coverLetter;
                    })
              : TaskEither<Failure, CoverLetter>.right(
                  CoverLetter(content: ''),
                );

          return coverLetterTask.flatMap((coverLetter) {
            final feedbackTask = includeFeedback
                ? TaskEither<Failure, Unit>.right(unit)
                      .map((_) => progress('Generating feedback'))
                      .flatMap(
                        (_) => generateFeedbackUsecase(
                          jobReq: jobReq,
                          resume: resume,
                          coverLetter: coverLetter,
                          prompt: prompt,
                          applicant: applicant,
                          tone: tone,
                          length: length,
                        ),
                      )
                      .map((feedback) {
                        progress('Feedback generated successfully');
                        return feedback;
                      })
                : TaskEither<Failure, Feedback>.right(Feedback(content: ''));

            return feedbackTask.flatMap((feedback) {
              final application = Application(
                applicant: applicant,
                jobReq: jobReq,
                resume: resume,
                coverLetter: coverLetter,
                feedback: feedback,
              );

              final jobReqId = jobReq.hashCode.toString();
              return saveJobReqAiResponseUsecase
                  .call(jobReqId: jobReqId)
                  .flatMap(
                    (_) => saveGigAiResponseUsecase.call(jobReqId: jobReqId),
                  )
                  .flatMap(
                    (_) => saveAssetAiResponseUsecase.call(jobReqId: jobReqId),
                  )
                  .flatMap(
                    (_) => saveResumeAiResponseUsecase.call(jobReqId: jobReqId),
                  )
                  .flatMap(
                    (_) => saveCoverLetterAiResponseUsecase.call(
                      jobReqId: jobReqId,
                    ),
                  )
                  .flatMap(
                    (_) =>
                        saveFeedbackAiResponseUsecase.call(jobReqId: jobReqId),
                  )
                  .map((_) {
                    progress('Application generated successfully');
                    return application;
                  });
            });
          });
        });
  }
}
