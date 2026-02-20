import 'package:fpdart/fpdart.dart';
import 'package:resumesux_application/resumesux_application.dart';

/// Use case for generating a resume.
class GenerateResumeUsecase {
  final AiService aiService;
  final ResumeRepository? resumeRepository;

  /// Creates a new instance of [GenerateResumeUsecase].
  GenerateResumeUsecase({
    required this.aiService,
    this.resumeRepository,
  });

  /// Generates a resume for the given job requirement and applicant.
  ///
  /// Parameters:
  /// - [jobReq]: The job requirement.
  /// - [applicant]: The applicant information.
  /// - [prompt]: The base prompt for AI generation.
  ///
  /// Returns: [TaskEither<Failure, Resume>] the generated resume or a failure.
  TaskEither<Failure, Resume> call({
    required JobReq jobReq,
    required Applicant applicant,
    required String prompt,
  }) {
    final gigsContent = applicant.gigs
        .map(
          (gig) =>
              '${gig.concern} - ${gig.title}\n${gig.achievements?.join('\n') ?? ''}',
        )
        .toList();
    final assetsContent =
        applicant.assets.map((asset) => asset.content).toList();

    final fullPrompt = _buildResumePrompt(
      jobReq: jobReq.content,
      gigs: gigsContent,
      assets: assetsContent,
      customPrompt: prompt,
      applicant: applicant,
    );

    return aiService.generateContent(prompt: fullPrompt).map((content) {
      resumeRepository?.setLastAiResponse({'content': content});
      return Resume(content: content);
    });
  }

  String _buildResumePrompt({
    required String jobReq,
    required List<String> gigs,
    required List<String> assets,
    required String customPrompt,
    required Applicant applicant,
  }) {
    final header = _buildApplicantHeader(applicant: applicant);
    return '''
$header

Generate an ATS-optimized resume. $customPrompt

Job Requirements:
$jobReq'

Work Experiences:
${gigs.map((g) => '---\n$g').join('\n')}

Qualifications:
${assets.map((a) => '---\n$a').join('\n')}

Please generate a resume in markdown format optimized for ATS systems.
Do not hallucinate any information. Use only the provided data.
Include all provided work experiences and qualifications. Do not add any skills, experiences, or qualifications not explicitly provided in the Work Experiences and Qualifications sections. If the provided data does not match the job requirements, still use only the provided data without modification or addition. Limit the resume to 1-2 pages. Quantify achievements where possible.
Output only the plain markdown content without any code blocks, backticks, or additional explanatory text.
''';
  }

  String _buildApplicantHeader({required Applicant applicant}) {
    final address = applicant.address;
    return '''
Applicant Information:
Name: ${applicant.name}
Preferred Name: ${applicant.preferredName}
Email: ${applicant.email}
Phone: ${applicant.phone}
${address != null ? 'Address: ${address.street1}${address.street2 != null ? ', ${address.street2}' : ''}, ${address.city}, ${address.state} ${address.zip}' : ''}
LinkedIn: ${applicant.linkedin}
GitHub: ${applicant.github}
Portfolio: ${applicant.portfolio}
''';
  }
}
